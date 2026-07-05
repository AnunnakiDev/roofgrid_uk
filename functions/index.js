const functions = require("firebase-functions");
const express = require("express");
const axios = require("axios");
const admin = require("firebase-admin");
require("dotenv").config(); // Load .env file for local testing

// Use environment variables (Firebase Secrets / Cloud Run env in production).
const stripeSecretKey = process.env.STRIPE_SECRET_KEY || "missing-stripe-secret-key";
const successUrl = process.env.STRIPE_SUCCESS_URL || "https://example.com/success";
const cancelUrl = process.env.STRIPE_CANCEL_URL || "https://example.com/cancel";
const monthlyPriceId =
  process.env.STRIPE_MONTHLY_PRICE_ID || "price_1RFcoEKk8BWeRfXO6ixJCKBG";
const annualPriceId =
  process.env.STRIPE_ANNUAL_PRICE_ID || "price_1RFcogKk8BWeRfXOzcS7rDva";
const labourPriceId =
  process.env.STRIPE_LABOUR_PRICE_ID || "price_labour_addon_placeholder";
const customerQuotePriceId =
  process.env.STRIPE_CUSTOMER_QUOTE_PRICE_ID ||
  "price_customer_quote_addon_placeholder";
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || "";
const recaptchaSecretKey = process.env.RECAPTCHA_SECRET_KEY || "";

functions.logger.info("Stripe config loaded", {
  hasStripeSecret: stripeSecretKey !== "missing-stripe-secret-key",
  hasWebhookSecret: webhookSecret.length > 0,
  hasLabourPriceId: !labourPriceId.includes("placeholder"),
  hasCustomerQuotePriceId: !customerQuotePriceId.includes("placeholder"),
});

if (stripeSecretKey === "missing-stripe-secret-key") {
  functions.logger.error("Stripe secret key is not set. Please set STRIPE_SECRET_KEY environment variable");
}

let stripe;
try {
  stripe = require("stripe")(stripeSecretKey);
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

// Health check endpoint
app.get("/health", (req, res) => {
  functions.logger.info("Health check received");
  res.status(200).send("OK");
});

// Stripe webhook must receive the raw body for signature verification.
app.post(
  "/stripeWebhook",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    try {
      functions.logger.info("stripeWebhook invoked");
      if (!webhookSecret) {
        functions.logger.error("STRIPE_WEBHOOK_SECRET is not configured");
        return res.status(503).send("Webhook secret not configured");
      }

      const sig = req.headers["stripe-signature"];
      let event;
      try {
        event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
      } catch (error) {
        functions.logger.error(
          "Webhook signature verification failed:",
          error.message,
        );
        return res.status(400).send(`Webhook Error: ${error.message}`);
      }

      const userRef = admin.firestore().collection("users");

      switch (event.type) {
        case "customer.subscription.created":
        case "customer.subscription.updated": {
          const subscription = event.data.object;
          const userId = subscription.metadata.firebaseUserId;
          const plan = subscription.metadata.plan;
          const product = subscription.metadata.product || plan;
          const subscriptionId = subscription.id;
          const subscriptionStatus = subscription.status;
          const subscriptionEndDate = new Date(
            subscription.current_period_end * 1000,
          );

          if (product === "labour" || plan === "labour") {
            await userRef.doc(userId).update({
              labourCalculatorActive: subscriptionStatus === "active",
              labourSubscriptionId: subscriptionId,
              labourSubscriptionPlan: plan,
              labourSubscriptionStatus: subscriptionStatus,
              labourSubscriptionEndDate: subscriptionEndDate,
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
            functions.logger.info(
              `Updated labour add-on for user ${userId}: ${subscriptionStatus}`,
            );
          } else if (product === "customerQuote" || plan === "customerQuote") {
            await userRef.doc(userId).update({
              customerQuoteActive: subscriptionStatus === "active",
              customerQuoteSubscriptionId: subscriptionId,
              customerQuoteSubscriptionPlan: plan,
              customerQuoteSubscriptionStatus: subscriptionStatus,
              customerQuoteSubscriptionEndDate: subscriptionEndDate,
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
            functions.logger.info(
              `Updated customer quote add-on for user ${userId}: ${subscriptionStatus}`,
            );
          } else {
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
            functions.logger.info(
              `Updated subscription for user ${userId}: ${subscriptionStatus}`,
            );
          }
          break;
        }

        case "customer.subscription.deleted": {
          const deletedSubscription = event.data.object;
          const deletedUserId = deletedSubscription.metadata.firebaseUserId;
          const deletedProduct =
            deletedSubscription.metadata.product ||
            deletedSubscription.metadata.plan;

          if (deletedProduct === "labour") {
            await userRef.doc(deletedUserId).update({
              labourCalculatorActive: false,
              labourSubscriptionId: null,
              labourSubscriptionPlan: null,
              labourSubscriptionStatus: "cancelled",
              labourSubscriptionEndDate: null,
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
            functions.logger.info(
              `Cancelled labour add-on for user ${deletedUserId}`,
            );
          } else if (deletedProduct === "customerQuote") {
            await userRef.doc(deletedUserId).update({
              customerQuoteActive: false,
              customerQuoteSubscriptionId: null,
              customerQuoteSubscriptionPlan: null,
              customerQuoteSubscriptionStatus: "cancelled",
              customerQuoteSubscriptionEndDate: null,
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
            functions.logger.info(
              `Cancelled customer quote add-on for user ${deletedUserId}`,
            );
          } else {
            await userRef.doc(deletedUserId).update({
              subscriptionId: null,
              subscriptionPlan: null,
              subscriptionStatus: "cancelled",
              subscriptionEndDate: null,
              role: "free",
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
            functions.logger.info(
              `Cancelled subscription for user ${deletedUserId}`,
            );
          }
          break;
        }

        default:
          functions.logger.info(`Unhandled event type: ${event.type}`);
      }

      return res.status(200).send("Webhook received");
    } catch (error) {
      functions.logger.error("Error in stripeWebhook:", error);
      return res.status(500).json({ error: error.message });
    }
  },
);

app.use(express.json());

const DESIGNATED_ADMIN_EMAILS = new Set([
  "support@roofgrid.uk",
  "hgwarner1307@gmail.com",
]);

// Verify Bearer ID token for any authenticated user.
const verifyAuthFromRequest = async (req) => {
  const authHeader = req.headers.authorization || "";
  const match = authHeader.match(/^Bearer (.+)$/i);
  if (!match) {
    const error = new Error("Missing Authorization Bearer token");
    error.statusCode = 403;
    throw error;
  }

  return admin.auth().verifyIdToken(match[1]);
};

// Verify Bearer ID token and ensure caller is an admin.
const verifyAdminFromRequest = async (req) => {
  const decoded = await verifyAuthFromRequest(req);
  const callerDoc = await admin
    .firestore()
    .collection("users")
    .doc(decoded.uid)
    .get();

  const callerRole = callerDoc.exists ? callerDoc.data().role : null;
  const callerEmail = decoded.email || callerDoc.data()?.email;
  const isDesignatedAdmin =
    callerEmail && DESIGNATED_ADMIN_EMAILS.has(callerEmail.toLowerCase());

  if (callerRole !== "admin" && !isDesignatedAdmin) {
    const error = new Error("Caller is not an admin");
    error.statusCode = 403;
    throw error;
  }

  return { uid: decoded.uid, callerDoc };
};

const deleteQueryBatch = async (query, batchSize = 200) => {
  const snapshot = await query.limit(batchSize).get();
  if (snapshot.empty) {
    return;
  }

  const batch = admin.firestore().batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  if (snapshot.size >= batchSize) {
    await deleteQueryBatch(query, batchSize);
  }
};

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

// Verify reCAPTCHA (HTTP endpoint — matches Flutter API client pattern)
app.post("/verifyCaptcha", async (req, res) => {
  try {
    await verifyAuthFromRequest(req);
    const data = req.body.data || req.body;
    const token = data?.token;
    if (!token) {
      functions.logger.error("No token provided");
      return res.status(400).json({ error: "No CAPTCHA token provided" });
    }
    if (!recaptchaSecretKey) {
      return res.status(503).json({ error: "reCAPTCHA is not configured" });
    }
    const secretKey = recaptchaSecretKey;

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

// Create a Stripe Checkout session
app.post("/createCheckoutSession", async (req, res) => {
  try {
    const decoded = await verifyAuthFromRequest(req);
    const data = req.body.data || req.body;
    const userId = decoded.uid;
    const plan = data?.plan; // "monthly", "annual", "labour", or "customerQuote"

    functions.logger.info("createCheckoutSession invoked", { userId, plan });

    // Validate plan
    if (!["monthly", "annual", "labour", "customerQuote"].includes(plan)) {
      return res.status(400).json({ error: "Invalid plan type" });
    }

    const userDoc = await getUserDoc(userId);
    const userData = userDoc.data();

    if (plan === "customerQuote") {
      const hasLabour =
        userData.labourCalculatorActive === true || userData.role === "admin";
      if (!hasLabour) {
        return res.status(403).json({
          error: "Labour calculator add-on required before customer quote",
        });
      }
      if (customerQuotePriceId.includes("placeholder")) {
        return res.status(503).json({
          error: "Customer quote checkout is not configured (missing price ID)",
        });
      }
    }

    if (plan === "labour" && labourPriceId.includes("placeholder")) {
      return res.status(503).json({
        error: "Labour checkout is not configured (missing price ID)",
      });
    }
    let stripeCustomerId = userData.stripeCustomerId;

    // Create a new Stripe customer if one doesn't exist
    if (!stripeCustomerId) {
      const customer = await stripe.customers.create({
        email: userData.email,
        metadata: { firebaseUserId: userId },
      });
      stripeCustomerId = customer.id;

      // Update Firestore with the Stripe customer ID
      await admin.firestore().collection("users").doc(userId).update({
        stripeCustomerId: stripeCustomerId,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    const isLabourPlan = plan === "labour";
    const isCustomerQuotePlan = plan === "customerQuote";
    const priceId = isLabourPlan
      ? labourPriceId
      : isCustomerQuotePlan
        ? customerQuotePriceId
        : plan === "monthly"
          ? monthlyPriceId
          : annualPriceId;
    const product = isLabourPlan
      ? "labour"
      : isCustomerQuotePlan
        ? "customerQuote"
        : "setout";

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
        product: product,
      },
      subscription_data: {
        metadata: {
          firebaseUserId: userId,
          plan: plan,
          product: product,
        },
      },
    });

    return res.status(200).json({ sessionUrl: session.url });
  } catch (error) {
    functions.logger.error("Error in createCheckoutSession:", error);
    return res.status(500).json({ error: error.message });
  }
});

// Create a Stripe Customer Portal session
app.post("/createCustomerPortalSession", async (req, res) => {
  try {
    const decoded = await verifyAuthFromRequest(req);
    const userId = decoded.uid;

    functions.logger.info("createCustomerPortalSession invoked", { userId });

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

// Admin: delete another user's Auth account and Firestore data
app.post("/adminDeleteUser", async (req, res) => {
  try {
    const { uid: callerUid } = await verifyAdminFromRequest(req);
    const targetUserId = req.body?.data?.targetUserId;

    if (!targetUserId || typeof targetUserId !== "string") {
      return res.status(400).json({ error: "targetUserId is required" });
    }

    if (targetUserId === callerUid) {
      return res.status(400).json({ error: "You cannot delete your own account" });
    }

    const targetDoc = await admin
      .firestore()
      .collection("users")
      .doc(targetUserId)
      .get();

    if (targetDoc.exists && targetDoc.data().role === "admin") {
      return res.status(400).json({ error: "Admin accounts cannot be deleted" });
    }

    const tilesQuery = admin
      .firestore()
      .collection("users")
      .doc(targetUserId)
      .collection("tiles");

    await deleteQueryBatch(tilesQuery);
    await admin.firestore().collection("users").doc(targetUserId).delete();

    try {
      await admin.auth().deleteUser(targetUserId);
    } catch (authError) {
      if (authError.code !== "auth/user-not-found") {
        throw authError;
      }
      functions.logger.warn(
        `Auth user ${targetUserId} not found; Firestore data removed`,
      );
    }

    functions.logger.info(`Admin ${callerUid} deleted user ${targetUserId}`);
    return res.status(200).json({ success: true, targetUserId });
  } catch (error) {
    functions.logger.error("Error in adminDeleteUser:", error);
    const status = error.statusCode || 500;
    return res.status(status).json({ error: error.message || "Delete failed" });
  }
});

// Admin: create a user without switching the caller's client session
app.post("/adminCreateUser", async (req, res) => {
  try {
    await verifyAdminFromRequest(req);
    const email = (req.body?.data?.email || "").trim().toLowerCase();
    const password = req.body?.data?.password || "";

    if (!email || !password) {
      return res.status(400).json({ error: "email and password are required" });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: "Password must be at least 6 characters" });
    }

    const userRecord = await admin.auth().createUser({ email, password });
    const now = admin.firestore.FieldValue.serverTimestamp();

    await admin.firestore().collection("users").doc(userRecord.uid).set({
      id: userRecord.uid,
      email,
      role: "free",
      createdAt: now,
      lastLoginAt: now,
    });

    functions.logger.info(`Admin created user ${userRecord.uid} (${email})`);
    return res.status(200).json({ success: true, userId: userRecord.uid });
  } catch (error) {
    functions.logger.error("Error in adminCreateUser:", error);
    const status = error.statusCode || 500;
    return res.status(status).json({ error: error.message || "Create failed" });
  }
});

// Export the Express app as a Cloud Function
exports.api = functions.https.onRequest(app);

// Log that the app has been set up
functions.logger.info("Express app setup completed, exporting as Cloud Function");