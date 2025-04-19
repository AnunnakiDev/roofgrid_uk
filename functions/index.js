const functions = require("firebase-functions");
const express = require("express");
const axios = require("axios");
const admin = require("firebase-admin");
require("dotenv").config(); // Load .env file for local testing

// Log environment variables for debugging
functions.logger.info("Environment variables:", {
  STRIPE_SECRET_KEY: process.env.STRIPE_SECRET_KEY,
  STRIPE_SUCCESS_URL: process.env.STRIPE_SUCCESS_URL,
  STRIPE_CANCEL_URL: process.env.STRIPE_CANCEL_URL,
});

// Use environment variables directly (required for 2nd Gen functions)
const stripeSecretKey = process.env.STRIPE_SECRET_KEY || "missing-stripe-secret-key";
const successUrl = process.env.STRIPE_SUCCESS_URL || "https://example.com/success";
const cancelUrl = process.env.STRIPE_CANCEL_URL || "https://example.com/cancel";

if (stripeSecretKey === "missing-stripe-secret-key") {
  functions.logger.error("Stripe secret key is not set. Please set STRIPE_SECRET_KEY environment variable");
}

try {
  const stripe = require("stripe")(stripeSecretKey);
  functions.logger.info("Stripe initialized successfully");
} catch (error) {
  functions.logger.error("Failed to initialize Stripe:", error);
  throw error;
}

// Initialize Firebase Admin
try {
  admin.initializeApp();
  functions.logger.info("Firebase Admin initialized successfully");
} catch (error) {
  functions.logger.error("Failed to initialize Firebase Admin:", error);
  throw error;
}

// Set up Express app
const app = express();
app.use(express.json());
app.use(express.raw({ type: "application/json" })); // For webhook raw body parsing

// Health check endpoint
app.get("/health", (req, res) => {
  functions.logger.info("Health check received");
  res.status(200).send("OK");
});

// Utility function to get user document
const getUserDoc = async (userId) => {
  try {
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    if (!userDoc.exists) {
      throw new Error(`User ${userId} not found`);
    }
    return userDoc;
  } catch (error) {
    functions.logger.error("Error in getUserDoc:", error);
    throw error;
  }
};

// Verify reCAPTCHA (callable function)
app.post("/verifyCaptcha", async (req, res) => {
  try {
    const data = req.body.data;
    const context = { auth: req.body.context }; // Simplified context for testing

    functions.logger.info("verifyCaptcha invoked", { data, context });
    if (!context.auth) {
      functions.logger.warn("Unauthenticated request", { context });
      return res.status(403).json({ error: "User must be authenticated" });
    }
    const { token } = data;
    if (!token) {
      functions.logger.error("No token provided");
      return res.status(400).json({ error: "No CAPTCHA token provided" });
    }
    const secretKey = "6Lc5GhsrAAAAACu-qlnWXbvQ26_ZyZqAY4s-xBvr"; // Replace with your secret key

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
      return res.status(200).json({ success: true });
    } else {
      functions.logger.warn("CAPTCHA verification failed", { response: response.data });
      return res.status(403).json({
        error: `CAPTCHA verification failed: ${response.data["error-codes"]?.join(", ") || "Unknown error"}`
      });
    }
  } catch (error) {
    functions.logger.error("Error in verifyCaptcha:", error);
    return res.status(500).json({
      error: `Error verifying CAPTCHA: ${error.message || "Unknown error"}`
    });
  }
});

// Create a Stripe Checkout session (callable function)
app.post("/createCheckoutSession", async (req, res) => {
  try {
    const data = req.body.data;
    const context = { auth: req.body.context }; // Simplified context for testing

    functions.logger.info("createCheckoutSession invoked", { data, context });
    if (!context.auth) {
      return res.status(403).json({ error: "User must be authenticated" });
    }

    const userId = context.auth.uid;
    const plan = data.plan; // "monthly" or "annual"

    // Validate plan
    if (!["monthly", "annual"].includes(plan)) {
      return res.status(400).json({ error: "Invalid plan type" });
    }

    // Get user document to check if they already have a Stripe customer ID
    const userDoc = await getUserDoc(userId);
    let stripeCustomerId = userDoc.data().stripeCustomerId;

    // Create a new Stripe customer if one doesn't exist
    if (!stripeCustomerId) {
      const customer = await stripe.customers.create({
        email: userDoc.data().email,
        metadata: { firebaseUserId: userId },
      });
      stripeCustomerId = customer.id;

      // Update Firestore with the Stripe customer ID
      await admin.firestore().collection("users").doc(userId).update({
        stripeCustomerId: stripeCustomerId,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Define price IDs
    const priceId =
      plan === "monthly"
        ? "price_1RFcoEKk8BWeRfXO6ixJCKBG" // Monthly price ID
        : "price_1RFcogKk8BWeRfXOzcS7rDva"; // Annual price ID

    // Create a Checkout session
    const session = await stripe.checkout.sessions.create({
      customer: stripeCustomerId,
      payment_method_types: ["card"],
      mode: "subscription",
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: {
        firebaseUserId: userId,
        plan: plan,
      },
    });

    return res.status(200).json({ sessionUrl: session.url });
  } catch (error) {
    functions.logger.error("Error in createCheckoutSession:", error);
    return res.status(500).json({ error: error.message });
  }
});

// Create a Stripe Customer Portal session (callable function)
app.post("/createCustomerPortalSession", async (req, res) => {
  try {
    const data = req.body.data;
    const context = { auth: req.body.context }; // Simplified context for testing

    functions.logger.info("createCustomerPortalSession invoked", { data, context });
    if (!context.auth) {
      return res.status(403).json({ error: "User must be authenticated" });
    }

    const userId = context.auth.uid;

    const userDoc = await getUserDoc(userId);
    const stripeCustomerId = userDoc.data().stripeCustomerId;

    if (!stripeCustomerId) {
      return res.status(400).json({ error: "No Stripe customer ID found for user" });
    }

    const portalSession = await stripe.billingPortal.sessions.create({
      customer: stripeCustomerId,
      return_url: successUrl,
    });

    return res.status(200).json({ portalUrl: portalSession.url });
  } catch (error) {
    functions.logger.error("Error in createCustomerPortalSession:", error);
    return res.status(500).json({ error: error.message });
  }
});

// Route for stripeWebhook
app.post("/stripeWebhook", async (req, res) => {
  try {
    functions.logger.info("stripeWebhook invoked");
    const sig = req.headers["stripe-signature"];
    const webhookSecret = "whsec_P5HlOZcsttV1n7XDMPway8gq9UDaRP1V"; // Stripe webhook secret

    let event;
    try {
      event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    } catch (error) {
      functions.logger.error("Webhook signature verification failed:", error.message);
      return res.status(400).send(`Webhook Error: ${error.message}`);
    }

    const userRef = admin.firestore().collection("users");

    switch (event.type) {
      case "customer.subscription.created":
      case "customer.subscription.updated":
        const subscription = event.data.object;
        const userId = subscription.metadata.firebaseUserId;
        const plan = subscription.metadata.plan;
        const subscriptionId = subscription.id;
        const subscriptionStatus = subscription.status;
        const subscriptionEndDate = new Date(subscription.current_period_end * 1000);

        await userRef.doc(userId).update({
          subscriptionId: subscriptionId,
          subscriptionPlan: plan,
          subscriptionStatus: subscriptionStatus,
          subscriptionEndDate: subscriptionEndDate,
          role: "pro",
          proTrialStartDate: null,
          proTrialEndDate: null,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        });
        functions.logger.info(`Updated subscription for user ${userId}: ${subscriptionStatus}`);
        break;

      case "customer.subscription.deleted":
        const deletedSubscription = event.data.object;
        const deletedUserId = deletedSubscription.metadata.firebaseUserId;

        await userRef.doc(deletedUserId).update({
          subscriptionId: null,
          subscriptionPlan: null,
          subscriptionStatus: "cancelled",
          subscriptionEndDate: null,
          role: "free",
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        });
        functions.logger.info(`Cancelled subscription for user ${deletedUserId}`);
        break;

      default:
        functions.logger.info(`Unhandled event type: ${event.type}`);
    }

    return res.status(200).send("Webhook received");
  } catch (error) {
    functions.logger.error("Error in stripeWebhook:", error);
    return res.status(500).json({ error: error.message });
  }
});

// Export the Express app as a Cloud Function
exports.api = functions.https.onRequest(app);

// Log that the app has been set up
functions.logger.info("Express app setup completed, exporting as Cloud Function");