package com.turbodevice

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import java.lang.reflect.InvocationHandler
import java.lang.reflect.Method
import java.lang.reflect.Proxy

class TurboDeviceInstallReferrerClient internal constructor(context: Context) {
  private val sharedPreferences: SharedPreferences
  private var mReferrerClient: Any?
  private var installReferrerStateListener: Any?

  init {
    sharedPreferences =
      context.getSharedPreferences("react-native-turbo-device", Context.MODE_PRIVATE)

    val newBuilderMethod = InstallReferrerClientClazz!!.getMethod(
      "newBuilder", Context::class.java
    )
    val builder = newBuilderMethod.invoke(null, context)
    val buildMethod = builder.javaClass.getMethod("build")
    mReferrerClient = buildMethod.invoke(builder)

    installReferrerStateListener = Proxy.newProxyInstance(
      InstallReferrerStateListenerClazz!!.classLoader, arrayOf(
        InstallReferrerStateListenerClazz
      ), InstallReferrerStateListenerProxy()
    )

    val startConnectionMethod =
      InstallReferrerClientClazz!!.getMethod("startConnection", InstallReferrerStateListenerClazz)
    startConnectionMethod.invoke(mReferrerClient, installReferrerStateListener)
  }

  private inner class InstallReferrerStateListenerProxy : InvocationHandler {
    @Throws(Throwable::class)
    override fun invoke(o: Any, method: Method, args: Array<Any>): Any? {
      val methodName = method.name
      try {
        if (methodName == "onInstallReferrerSetupFinished" && args[0] is Int) {
          onInstallReferrerSetupFinished(args[0] as Int)
        } else if (methodName == "onInstallReferrerServiceDisconnected") {
          onInstallReferrerServiceDisconnected()
        }
      } catch (e: Exception) {
        throw RuntimeException("unexpected invocation exception: " + e.message)
      }
      return null
    }

    fun onInstallReferrerSetupFinished(responseCode: Int) {
      when (responseCode) {
        R_RESPONSE_OK -> try {
          Log.d("InstallReferrerState", "OK")
          val getInstallReferrerMethod =
            InstallReferrerClientClazz!!.getMethod("getInstallReferrer")
          val response = getInstallReferrerMethod.invoke(mReferrerClient)
          val getInstallReferrerMethod2 = ReferrerDetailsClazz!!.getMethod("getInstallReferrer")
          val referrer = getInstallReferrerMethod2.invoke(response) as String
          val editor = sharedPreferences.edit()
          editor.putString("installReferrer", referrer)
          editor.apply()
          val endConnectionMethod = InstallReferrerClientClazz!!.getMethod("endConnection")
          endConnectionMethod.invoke(mReferrerClient)
        } catch (e: Exception) {
          System.err.println("InstallReferrerClient exception. getInstallReferrer will be unavailable: " + e.message)
          e.printStackTrace(System.err)
        }

        R_RESPONSE_FEATURE_NOT_SUPPORTED -> Log.d("InstallReferrerState", "FEATURE_NOT_SUPPORTED")

        R_RESPONSE_SERVICE_UNAVAILABLE -> Log.d("InstallReferrerState", "SERVICE_UNAVAILABLE")
      }
    }

    fun onInstallReferrerServiceDisconnected() {
      Log.d("InstallReferrerClient", "InstallReferrerService disconnected")
    }
  }

  companion object {
    private var InstallReferrerClientClazz: Class<*>? = null
    private var InstallReferrerStateListenerClazz: Class<*>? = null
    private var ReferrerDetailsClazz: Class<*>? = null

    private const val R_RESPONSE_OK = 0
    private const val R_RESPONSE_SERVICE_UNAVAILABLE = 1
    private const val R_RESPONSE_FEATURE_NOT_SUPPORTED = 2
  }
}
