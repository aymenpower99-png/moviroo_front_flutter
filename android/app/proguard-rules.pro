# ProGuard rules for Moviroo release build

# Stripe SDK pushProvisioning — these classes are missing from the default
# Stripe SDK distribution but are referenced by react-native-stripe-sdk internals.
# Safe to ignore because push provisioning is not used in this app.
-dontwarn com.stripe.android.pushProvisioning.**
