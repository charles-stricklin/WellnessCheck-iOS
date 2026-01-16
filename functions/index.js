/**
 * WellnessCheck Cloud Functions
 *
 * These functions handle SMS messaging via Twilio for the WellnessCheck app.
 * All functions require authentication - only signed-in users can trigger them.
 */

const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

// Define secrets for Twilio credentials (stored securely in Google Secret Manager)
const twilioAccountSid = defineSecret("TWILIO_ACCOUNT_SID");
const twilioAuthToken = defineSecret("TWILIO_AUTH_TOKEN");
const twilioPhoneNumber = defineSecret("TWILIO_PHONE_NUMBER");

// Limit concurrent instances for cost control
setGlobalOptions({ maxInstances: 10 });

/**
 * Send "I'm OK" message to all Care Circle members
 *
 * Called when user taps the "I'm OK" button in the app.
 * Sends a reassuring SMS to all Care Circle members.
 *
 * @param {Object} data - Contains userName (string) and members (array of {name, phone})
 * @returns {Object} - Success status and count of messages sent
 */
exports.sendImOkMessage = onCall(
  { secrets: [twilioAccountSid, twilioAuthToken, twilioPhoneNumber] },
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to send messages."
      );
    }

    const { userName, members } = request.data;

    // Validate input
    if (!userName || !members || !Array.isArray(members) || members.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "userName and members array are required."
      );
    }

    // Initialize Twilio client
    const twilio = require("twilio")(
      twilioAccountSid.value(),
      twilioAuthToken.value()
    );

    const results = [];
    const fromNumber = twilioPhoneNumber.value();

    // Send SMS to each Care Circle member
    for (const member of members) {
      if (!member.phone) continue;

      const message = `Hi ${member.name}, this is an update from WellnessCheck: ${userName} wanted you to know they're doing fine. No action needed!`;

      try {
        const result = await twilio.messages.create({
          body: message,
          from: fromNumber,
          to: member.phone,
        });

        logger.info(`SMS sent to ${member.name}`, {
          sid: result.sid,
          userId: request.auth.uid
        });

        results.push({ name: member.name, success: true });
      } catch (error) {
        logger.error(`Failed to send SMS to ${member.name}`, {
          error: error.message,
          userId: request.auth.uid
        });

        results.push({ name: member.name, success: false, error: error.message });
      }
    }

    const successCount = results.filter(r => r.success).length;

    return {
      success: successCount > 0,
      sent: successCount,
      total: members.length,
      results: results,
    };
  }
);

/**
 * Send alert to Care Circle members when user may need help
 *
 * Called by the monitoring system when:
 * - User doesn't respond to a check-in
 * - Fall detected and user doesn't confirm they're OK
 * - Unusual inactivity pattern detected
 *
 * @param {Object} data - Contains userName, alertType, location (optional), and members array
 * @returns {Object} - Success status and escalation info
 */
exports.sendAlert = onCall(
  { secrets: [twilioAccountSid, twilioAuthToken, twilioPhoneNumber] },
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to send alerts."
      );
    }

    const { userName, alertType, location, members } = request.data;

    // Validate input
    if (!userName || !alertType || !members || members.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "userName, alertType, and members are required."
      );
    }

    // Initialize Twilio client
    const twilio = require("twilio")(
      twilioAccountSid.value(),
      twilioAuthToken.value()
    );

    const fromNumber = twilioPhoneNumber.value();

    // Build alert message based on type
    let message;
    switch (alertType) {
      case "inactivity":
        message = `WellnessCheck Alert: ${userName} hasn't responded to check-ins for an extended period.`;
        break;
      case "fall":
        message = `WellnessCheck Alert: A possible fall was detected for ${userName} and they haven't confirmed they're OK.`;
        break;
      case "missed_checkin":
        message = `WellnessCheck Alert: ${userName} missed their scheduled check-in.`;
        break;
      default:
        message = `WellnessCheck Alert: ${userName} may need assistance.`;
    }

    // Add location if available
    if (location && location.address) {
      message += ` Location: ${location.address}`;
      if (location.isHome === false) {
        message += " (away from home)";
      }
    }

    message += " Please check on them when you can.";

    const results = [];

    // Send to members in priority order
    for (const member of members) {
      if (!member.phone) continue;

      try {
        const result = await twilio.messages.create({
          body: message,
          from: fromNumber,
          to: member.phone,
        });

        logger.info(`Alert sent to ${member.name}`, {
          sid: result.sid,
          alertType: alertType,
          userId: request.auth.uid,
        });

        results.push({ name: member.name, success: true, sid: result.sid });
      } catch (error) {
        logger.error(`Failed to send alert to ${member.name}`, {
          error: error.message,
          alertType: alertType,
          userId: request.auth.uid,
        });

        results.push({ name: member.name, success: false, error: error.message });
      }
    }

    const successCount = results.filter(r => r.success).length;

    return {
      success: successCount > 0,
      sent: successCount,
      total: members.length,
      alertType: alertType,
      results: results,
    };
  }
);

/**
 * Send Care Circle invitation SMS
 *
 * Called when user adds a new Care Circle member and wants to invite them.
 *
 * @param {Object} data - Contains userName, memberName, memberPhone
 * @returns {Object} - Success status
 */
exports.sendInvitation = onCall(
  { secrets: [twilioAccountSid, twilioAuthToken, twilioPhoneNumber] },
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to send invitations."
      );
    }

    const { userName, memberName, memberPhone } = request.data;

    // Validate input
    if (!userName || !memberName || !memberPhone) {
      throw new HttpsError(
        "invalid-argument",
        "userName, memberName, and memberPhone are required."
      );
    }

    // Initialize Twilio client
    const twilio = require("twilio")(
      twilioAccountSid.value(),
      twilioAuthToken.value()
    );

    const fromNumber = twilioPhoneNumber.value();

    const message = `Hi ${memberName}! ${userName} has added you to their Care Circle on WellnessCheck. You'll receive updates about their wellbeing and alerts if they need help. Reply STOP to opt out.`;

    try {
      const result = await twilio.messages.create({
        body: message,
        from: fromNumber,
        to: memberPhone,
      });

      logger.info(`Invitation sent to ${memberName}`, {
        sid: result.sid,
        userId: request.auth.uid,
      });

      return {
        success: true,
        sid: result.sid,
      };
    } catch (error) {
      logger.error(`Failed to send invitation to ${memberName}`, {
        error: error.message,
        userId: request.auth.uid,
      });

      throw new HttpsError(
        "internal",
        `Failed to send invitation: ${error.message}`
      );
    }
  }
);
