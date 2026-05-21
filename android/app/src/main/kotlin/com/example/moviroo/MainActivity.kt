package com.example.moviroo

import android.os.Bundle
import android.util.Log
import androidx.credentials.*
import androidx.credentials.exceptions.*
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import org.json.JSONObject
import org.json.JSONArray

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.moviroo/webauthn"
    private lateinit var credentialManager: CredentialManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        credentialManager = CredentialManager.create(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "register" -> {
                    val options = call.argument<String>("options") ?: ""
                    handleRegister(options, result)
                }
                "authenticate" -> {
                    val options = call.argument<String>("options") ?: ""
                    handleAuthenticate(options, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleRegister(options: String, result: MethodChannel.Result) {
        Log.d("WebAuthn", "Register options JSON: $options")
        val request = CreatePublicKeyCredentialRequest(options)
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val response = credentialManager.createCredential(
                    context = this@MainActivity,
                    request = request,
                ) as CreatePublicKeyCredentialResponse

                val json = JSONObject(response.registrationResponseJson)
                val id = json.getString("id")
                val rawId = json.optString("rawId", id)
                val type = json.optString("type", "public-key")
                val responseObj = json.getJSONObject("response")

                result.success(
                    mapOf(
                        "id" to id,
                        "rawId" to rawId,
                        "type" to type,
                        "response" to mapOf(
                            "clientDataJSON" to responseObj.getString("clientDataJSON"),
                            "attestationObject" to responseObj.getString("attestationObject"),
                        ),
                        "clientExtensionResults" to jsonObjectToMap(json.optJSONObject("clientExtensionResults"))
                    )
                )
            } catch (e: CreateCredentialException) {
                Log.e("WebAuthn", "CreateCredentialException: ${e.javaClass.name} — ${e.message}")
                result.error("REGISTRATION_ERROR", "[${e.javaClass.simpleName}] ${e.message}", null)
            } catch (e: Exception) {
                Log.e("WebAuthn", "Exception: ${e.javaClass.name} — ${e.message}")
                result.error("REGISTRATION_ERROR", e.message, null)
            }
        }
    }

    private fun handleAuthenticate(options: String, result: MethodChannel.Result) {
        Log.d("WebAuthn", "Authenticate options JSON: $options")
        val option = GetPublicKeyCredentialOption(options)
        val request = GetCredentialRequest(listOf(option))
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val response = credentialManager.getCredential(
                    context = this@MainActivity,
                    request = request,
                )
                val credential = response.credential as PublicKeyCredential
                val json = JSONObject(credential.authenticationResponseJson)

                val id = json.getString("id")
                val rawId = json.optString("rawId", id)
                val type = json.optString("type", "public-key")
                val responseObj = json.getJSONObject("response")

                result.success(
                    mapOf(
                        "id" to id,
                        "rawId" to rawId,
                        "type" to type,
                        "response" to mapOf(
                            "clientDataJSON" to responseObj.getString("clientDataJSON"),
                            "authenticatorData" to responseObj.getString("authenticatorData"),
                            "signature" to responseObj.getString("signature"),
                            "userHandle" to responseObj.optString("userHandle", ""),
                        ),
                        "clientExtensionResults" to jsonObjectToMap(json.optJSONObject("clientExtensionResults"))
                    )
                )
            } catch (e: GetCredentialException) {
                Log.e("WebAuthn", "GetCredentialException: ${e.javaClass.name} — ${e.message}")
                result.error("AUTHENTICATION_ERROR", "[${e.javaClass.simpleName}] ${e.message}", null)
            } catch (e: Exception) {
                Log.e("WebAuthn", "Exception: ${e.javaClass.name} — ${e.message}")
                result.error("AUTHENTICATION_ERROR", e.message, null)
            }
        }
    }

    /** Recursively convert a JSONObject into a plain Kotlin Map so Flutter's
     *  StandardMessageCodec can serialise it (it does not understand JSONObject).
     */
    private fun jsonObjectToMap(json: JSONObject?): Map<String, Any?>? {
        if (json == null) return null
        val map = mutableMapOf<String, Any?>()
        for (key in json.keys()) {
            val value = json.get(key)
            map[key] = when (value) {
                is JSONObject -> jsonObjectToMap(value)
                is JSONArray -> jsonArrayToList(value)
                else -> value
            }
        }
        return map
    }

    private fun jsonArrayToList(array: JSONArray): List<Any?> {
        val list = mutableListOf<Any?>()
        for (i in 0 until array.length()) {
            val value = array.get(i)
            list.add(when (value) {
                is JSONObject -> jsonObjectToMap(value)
                is JSONArray -> jsonArrayToList(value)
                else -> value
            })
        }
        return list
    }
}
