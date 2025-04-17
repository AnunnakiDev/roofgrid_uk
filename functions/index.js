const functions = require("firebase-functions");
const axios = require("axios");

exports.verifyCaptcha = functions.https.onCall(async (data, context) => {
  functions.logger.info("verifyCaptcha invoked", { data, context });
  if (!context.auth) {
    functions.logger.warn("Unauthenticated request", { context });
  }
  const { token } = data;
  if (!token) {
    functions.logger.error("No token provided");
    throw new functions.https.HttpsError("invalid-argument", "No CAPTCHA token provided");
  }
  const secretKey = "6Lc5GhsrAAAAACu-qlnWXbvQ26_ZyZqAY4s-xBvr"; // Replace with your secret key

  try {
    functions.logger.info("Sending request to reCAPTCHA API", { token });
    const response = await axios.post(
      "https://www.google.com/recaptcha/api/siteverify",
      null,
      {
        params: {
          secret: secretKey,
          response: token,
        },
      }
    );
    functions.logger.info("reCAPTCHA API response", { response: response.data });

    if (response.data.success && response.data.score >= 0.5) {
      functions.logger.info("CAPTCHA verification successful", { score: response.data.score });
      return { success: true };
    } else {
      functions.logger.warn("CAPTCHA verification failed", { response: response.data });
      throw new functions.https.HttpsError(
        "permission-denied",
        `CAPTCHA verification failed: ${response.data["error-codes"]?.join(", ") || "Unknown error"}`
      );
    }
  } catch (error) {
    functions.logger.error("Error verifying CAPTCHA", { error: error.message, response: error.response?.data });
    throw new functions.https.HttpsError(
      "internal",
      `Error verifying CAPTCHA: ${error.message || "Unknown error"}`
    );
  }
});