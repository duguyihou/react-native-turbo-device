package com.turbodevice

import android.Manifest
import android.annotation.SuppressLint
import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.content.pm.FeatureInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.hardware.camera2.CameraManager
import android.location.LocationManager
import android.media.AudioManager
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.os.Debug
import android.os.Environment
import android.os.PowerManager
import android.os.Process
import android.os.StatFs
import android.provider.Settings
import android.provider.Settings.Secure
import android.telephony.TelephonyManager
import android.webkit.WebSettings
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeArray
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.modules.core.DeviceEventManagerModule
import java.lang.reflect.Method
import java.math.BigInteger
import java.net.InetAddress
import java.net.NetworkInterface
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Collections
import javax.annotation.Nonnull

@ReactModule(name = TurboDeviceModule.NAME)
class TurboDeviceModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {
  private val deviceTypeResolver: DeviceTypeResolver
  private val deviceIdResolver: DeviceIdResolver
  private var receiver: BroadcastReceiver? = null
  private var headphoneConnectionReceiver: BroadcastReceiver? = null
  private val installReferrerClient: TurboDeviceInstallReferrerClient
  private var mLastBatteryLevel: Double = -1.0
  private var mLastBatteryState: String? = ""
  private var mLastPowerSaveState: Boolean = false

  init {
    deviceTypeResolver = DeviceTypeResolver(reactContext)
    deviceIdResolver = DeviceIdResolver(reactContext)
    installReferrerClient = TurboDeviceInstallReferrerClient(reactContext.baseContext)
  }

  override fun initialize() {
    val filter = IntentFilter()
    filter.addAction(Intent.ACTION_BATTERY_CHANGED)
    filter.addAction(Intent.ACTION_POWER_CONNECTED)
    filter.addAction(Intent.ACTION_POWER_DISCONNECTED)
    filter.addAction(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
    receiver = object : BroadcastReceiver() {
      override fun onReceive(context: Context, intent: Intent) {
        val powerState: WritableMap = getPowerStateFromIntent(intent) ?: return
        val batteryState: String? = powerState.getString(BATTERY_STATE)
        val batteryLevel: Double = powerState.getDouble(BATTERY_LEVEL)
        val powerSaveState: Boolean = powerState.getBoolean(LOW_POWER_MODE)
        if (!mLastBatteryState.equals(
            batteryState,
            ignoreCase = true
          ) || mLastPowerSaveState != powerSaveState
        ) {
          sendEvent(reactApplicationContext, "TurboDevice_powerStateDidChange", batteryState)
          mLastBatteryState = batteryState
          mLastPowerSaveState = powerSaveState
        }
        if (mLastBatteryLevel != batteryLevel) {
          sendEvent(reactApplicationContext, "TurboDevice_batteryLevelDidChange", batteryLevel)
          if (batteryLevel <= .15) {
            sendEvent(reactApplicationContext, "TurboDevice_batteryLevelIsLow", batteryLevel)
          }
          mLastBatteryLevel = batteryLevel
        }
      }
    }
    reactApplicationContext.registerReceiver(receiver, filter)
    initializeHeadphoneConnectionReceiver()
  }

  private fun initializeHeadphoneConnectionReceiver() {
    val filter = IntentFilter()
    filter.addAction(AudioManager.ACTION_HEADSET_PLUG)
    filter.addAction(AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED)
    headphoneConnectionReceiver = object : BroadcastReceiver() {
      override fun onReceive(context: Context, intent: Intent) {
        val isConnected: Boolean = isHeadphonesConnected
        sendEvent(reactApplicationContext, "TurboDevice_headphoneConnectionDidChange", isConnected)
      }
    }
    reactApplicationContext.registerReceiver(headphoneConnectionReceiver, filter)
  }

  @Nonnull
  override fun getName(): String {
    return NAME
  }

  @get:SuppressLint("MissingPermission")
  private val wifiInfo: WifiInfo?
    get() {
      val manager: WifiManager = reactApplicationContext.applicationContext.getSystemService(
        Context.WIFI_SERVICE
      ) as WifiManager
      return manager.connectionInfo
    }

  @get:Nonnull
  private val isLowRamDevice: Boolean
    get() {
      val am: ActivityManager =
        reactApplicationContext.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
      return am.isLowRamDevice
    }

  override fun getConstants(): Map<String, Any> {
    var appVersion: String
    var buildNumber: String
    var appName: String
    try {
      appVersion = packageInfo.versionName
      buildNumber = packageInfo.versionCode.toString()
      appName =
        reactApplicationContext.applicationInfo.loadLabel(reactApplicationContext.packageManager)
          .toString()
    } catch (e: Exception) {
      appVersion = "unknown"
      buildNumber = "unknown"
      appName = "unknown"
    }
    val constants: MutableMap<String, Any> = HashMap()
    constants["deviceId"] = Build.BOARD
    constants["bundleId"] = reactApplicationContext.packageName
    constants["systemName"] = "Android"
    constants["systemVersion"] = Build.VERSION.RELEASE
    constants["appVersion"] = appVersion
    constants["buildNumber"] = buildNumber
    constants["isTablet"] = deviceTypeResolver.isTablet
    constants["isLowRamDevice"] = isLowRamDevice
    constants["appName"] = appName
    constants["brand"] = Build.BRAND
    constants["model"] = Build.MODEL
    constants["deviceType"] = deviceTypeResolver.deviceType.value
    return constants
  }

  @ReactMethod
  fun isEmulator(p: Promise) {
    p.resolve(isEmulator)
  }

  @get:ReactMethod
  @get:SuppressLint("HardwareIds")
  val isEmulator: Boolean
    get() = (Build.FINGERPRINT.startsWith("generic")
      || Build.FINGERPRINT.startsWith("unknown")
      || Build.MODEL.contains("google_sdk")
      || Build.MODEL.lowercase().contains("droid4x")
      || Build.MODEL.contains("Emulator")
      || Build.MODEL.contains("Android SDK built for x86")
      || Build.MANUFACTURER.contains("Genymotion")
      || Build.HARDWARE.contains("goldfish")
      || Build.HARDWARE.contains("ranchu")
      || Build.HARDWARE.contains("vbox86")
      || Build.PRODUCT.contains("sdk")
      || Build.PRODUCT.contains("google_sdk")
      || Build.PRODUCT.contains("sdk_google")
      || Build.PRODUCT.contains("sdk_x86")
      || Build.PRODUCT.contains("vbox86p")
      || Build.PRODUCT.contains("emulator")
      || Build.PRODUCT.contains("simulator")
      || Build.BOARD.lowercase().contains("nox")
      || Build.BOOTLOADER.lowercase().contains("nox")
      || Build.HARDWARE.lowercase().contains("nox")
      || Build.PRODUCT.lowercase().contains("nox")
      || Build.SERIAL.lowercase().contains("nox")
      || (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")))

  @get:ReactMethod
  val fontScale: Float
    get() {
      return reactApplicationContext.resources.configuration.fontScale
    }

  @ReactMethod
  fun getFontScale(p: Promise) {
    p.resolve(fontScale)
  }

  @get:ReactMethod
  val isPinOrFingerprintSet: Boolean
    get() {
      val keyguardManager: KeyguardManager =
        reactApplicationContext.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
      return keyguardManager.isKeyguardSecure
    }

  @ReactMethod
  fun isPinOrFingerprintSet(p: Promise) {
    p.resolve(isPinOrFingerprintSet)
  }

  @get:ReactMethod
  val ipAddress: String
    get() {
      return InetAddress.getByAddress(
        ByteBuffer
          .allocate(4)
          .order(ByteOrder.LITTLE_ENDIAN)
          .putInt(wifiInfo!!.ipAddress)
          .array()
      )
        .hostAddress?.toString() ?: "unknown"
    }

  @ReactMethod
  fun getIpAddress(p: Promise) {
    p.resolve(ipAddress)
  }

  @get:ReactMethod
  val isCameraPresent: Boolean
    get() {
      val manager: CameraManager =
        reactApplicationContext.getSystemService(Context.CAMERA_SERVICE) as CameraManager
      return try {
        manager.cameraIdList.isNotEmpty()
      } catch (e: Exception) {
        false
      }
    }

  @ReactMethod
  fun isCameraPresent(p: Promise) {
    p.resolve(isCameraPresent)
  }

  @get:ReactMethod
  @get:SuppressLint("HardwareIds")
  val macAddress: String
    get() {
      val wifiInfo: WifiInfo? = wifiInfo
      var macAddress = ""
      if (wifiInfo != null) {
        macAddress = wifiInfo.macAddress
      }
      val permission = "android.permission.INTERNET"
      val res: Int = reactApplicationContext.checkCallingOrSelfPermission(permission)
      if (res == PackageManager.PERMISSION_GRANTED) {
        try {
          val all: List<NetworkInterface> =
            Collections.list(NetworkInterface.getNetworkInterfaces())
          for (nif: NetworkInterface in all) {
            if (!nif.name.equals("wlan0", ignoreCase = true)) continue
            val macBytes: ByteArray? = nif.hardwareAddress
            macAddress = if (macBytes == null) {
              ""
            } else {
              val res1: StringBuilder = StringBuilder()
              for (b: Byte in macBytes) {
                res1.append(String.format("%02X:", b))
              }
              if (res1.isNotEmpty()) {
                res1.deleteCharAt(res1.length - 1)
              }
              res1.toString()
            }
          }
        } catch (ex: Exception) {
          // do nothing
        }
      }
      return macAddress
    }

  @ReactMethod
  fun getMacAddress(p: Promise) {
    p.resolve(macAddress)
  }

  @get:ReactMethod
  val carrier: String
    get() {
      val telMgr: TelephonyManager =
        reactApplicationContext.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
      return telMgr.networkOperatorName
    }

  @ReactMethod
  fun getCarrier(p: Promise) {
    p.resolve(carrier)
  }

  @get:ReactMethod
  val totalDiskCapacity: Double
    get() {
      return try {
        val rootDir = StatFs(Environment.getRootDirectory().absolutePath)
        val dataDir = StatFs(Environment.getDataDirectory().absolutePath)
        val rootDirCapacity: BigInteger = getDirTotalCapacity(rootDir)
        val dataDirCapacity: BigInteger = getDirTotalCapacity(dataDir)
        rootDirCapacity.add(dataDirCapacity).toDouble()
      } catch (e: Exception) {
        (-1).toDouble()
      }
    }

  @ReactMethod
  fun getTotalDiskCapacity(p: Promise) {
    p.resolve(totalDiskCapacity)
  }

  private fun getDirTotalCapacity(dir: StatFs): BigInteger {
    val blockCount: Long = dir.blockCountLong
    val blockSize: Long = dir.blockSizeLong
    return BigInteger.valueOf(blockCount).multiply(BigInteger.valueOf(blockSize))
  }

  @get:ReactMethod
  val freeDiskStorage: Double
    get() {
      try {
        val rootDir = StatFs(Environment.getRootDirectory().absolutePath)
        val dataDir = StatFs(Environment.getDataDirectory().absolutePath)
        val rootAvailableBlocks: Long = getTotalAvailableBlocks(rootDir)
        val rootBlockSize: Long = getBlockSize(rootDir)
        val rootFree: Double =
          BigInteger.valueOf(rootAvailableBlocks).multiply(BigInteger.valueOf(rootBlockSize))
            .toDouble()
        val dataAvailableBlocks: Long = getTotalAvailableBlocks(dataDir)
        val dataBlockSize: Long = getBlockSize(dataDir)
        val dataFree: Double =
          BigInteger.valueOf(dataAvailableBlocks).multiply(BigInteger.valueOf(dataBlockSize))
            .toDouble()
        return rootFree + dataFree
      } catch (e: Exception) {
        return (-1).toDouble()
      }
    }

  @ReactMethod
  fun getFreeDiskStorage(p: Promise) {
    p.resolve(freeDiskStorage)
  }

  private fun getTotalAvailableBlocks(dir: StatFs): Long {
    return dir.availableBlocksLong
  }

  private fun getBlockSize(dir: StatFs): Long {
    return dir.blockSizeLong
  }

  @get:ReactMethod
  val isBatteryCharging: Boolean
    get() {
      val ifilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
      val batteryStatus: Intent? = reactApplicationContext.registerReceiver(null, ifilter)
      var status = 0
      if (batteryStatus != null) {
        status = batteryStatus.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
      }
      return status == BatteryManager.BATTERY_STATUS_CHARGING
    }

  @ReactMethod
  fun isBatteryCharging(p: Promise) {
    p.resolve(isBatteryCharging)
  }

  @get:ReactMethod
  val usedMemory: Double
    get() {
      val actMgr: ActivityManager =
        reactApplicationContext.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
      val pid: Int = Process.myPid()
      val memInfoArray: Array<Debug.MemoryInfo> = actMgr.getProcessMemoryInfo(
        intArrayOf(pid)
      )
      if (memInfoArray.size != 1) {
        System.err.println("Unable to getProcessMemoryInfo. getProcessMemoryInfo did not return any info for the PID")
        return (-1).toDouble()
      }
      val memInfo: Debug.MemoryInfo = memInfoArray[0]
      return memInfo.totalPss * 1024.0
    }

  @ReactMethod
  fun getUsedMemory(p: Promise) {
    p.resolve(usedMemory)
  }

  @get:ReactMethod
  val powerState: WritableMap?
    get() {
      val intent: Intent? =
        reactApplicationContext.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
      return getPowerStateFromIntent(intent)
    }

  @ReactMethod
  fun getPowerState(p: Promise) {
    p.resolve(powerState)
  }

  @get:ReactMethod
  val batteryLevel: Double
    get() {
      val intent: Intent? =
        reactApplicationContext.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
      val powerState: WritableMap = getPowerStateFromIntent(intent) ?: return 0.0
      return powerState.getDouble(BATTERY_LEVEL)
    }

  @ReactMethod
  fun getBatteryLevel(p: Promise) {
    p.resolve(batteryLevel)
  }

  @get:ReactMethod
  val isAirplaneMode: Boolean
    get() {
      return Settings.Global.getInt(
        reactApplicationContext.contentResolver,
        Settings.Global.AIRPLANE_MODE_ON,
        0
      ) != 0
    }

  @ReactMethod
  fun isAirplaneMode(p: Promise) {
    p.resolve(isAirplaneMode)
  }

  @ReactMethod
  fun hasGms(): Boolean {
    try {
      val googleApiAvailability: Class<*> =
        Class.forName("com.google.android.gms.common.GoogleApiAvailability")
      val getInstanceMethod: Method = googleApiAvailability.getMethod("getInstance")
      val gmsObject: Any? = getInstanceMethod.invoke(null)
      val isGooglePlayServicesAvailable: Method? = gmsObject?.javaClass?.getMethod(
        "isGooglePlayServicesAvailable",
        Context::class.java
      )
      val isGMS = isGooglePlayServicesAvailable?.invoke(
        gmsObject,
        reactApplicationContext
      )
      return isGMS == 0 // ConnectionResult.SUCCESS
    } catch (e: Exception) {
      return false
    }
  }

  @ReactMethod
  fun hasGms(p: Promise) {
    p.resolve(hasGms())
  }

  @ReactMethod
  fun hasHms(): Boolean {
    try {
      val huaweiApiAvailability: Class<*> =
        Class.forName("com.huawei.hms.api.HuaweiApiAvailability")
      val getInstanceMethod: Method = huaweiApiAvailability.getMethod("getInstance")
      val hmsObject: Any? = getInstanceMethod.invoke(null)
      val isHuaweiMobileServicesAvailableMethod: Method? = hmsObject?.javaClass?.getMethod(
        "isHuaweiMobileServicesAvailable",
        Context::class.java
      )
      val isHMS: Int = isHuaweiMobileServicesAvailableMethod?.invoke(
        hmsObject,
        reactApplicationContext
      ) as Int
      return isHMS == 0 // ConnectionResult.SUCCESS
    } catch (e: Exception) {
      return false
    }
  }

  @ReactMethod
  fun hasHms(p: Promise) {
    p.resolve(hasHms())
  }

  @ReactMethod
  fun hasSystemFeature(feature: String?): Boolean {
    if (feature == null || (feature == "")) {
      return false
    }
    return reactApplicationContext.packageManager.hasSystemFeature(feature)
  }

  @ReactMethod
  fun hasSystemFeature(feature: String?, p: Promise) {
    p.resolve(hasSystemFeature(feature))
  }

  @get:ReactMethod
  val systemAvailableFeatures: WritableArray
    get() {
      val featureList: Array<FeatureInfo> =
        reactApplicationContext.packageManager.systemAvailableFeatures
      val promiseArray: WritableArray = Arguments.createArray()
      for (f: FeatureInfo in featureList) {
        if (f.name != null) {
          promiseArray.pushString(f.name)
        }
      }
      return promiseArray
    }

  @ReactMethod
  fun getSystemAvailableFeatures(p: Promise) {
    p.resolve(systemAvailableFeatures)
  }

  @get:ReactMethod
  val isLocationEnabled: Boolean
    get() {
      val locationEnabled: Boolean
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        val mLocationManager: LocationManager = reactApplicationContext.getSystemService(
          Context.LOCATION_SERVICE
        ) as LocationManager
        try {
          locationEnabled = mLocationManager.isLocationEnabled
        } catch (e: Exception) {
          System.err.println("Unable to determine if location enabled. LocationManager was null")
          return false
        }
      } else {
        val locationMode: Int = Secure.getInt(
          reactApplicationContext.contentResolver, Secure.LOCATION_MODE, Secure.LOCATION_MODE_OFF
        )
        locationEnabled = locationMode != Secure.LOCATION_MODE_OFF
      }
      return locationEnabled
    }

  @ReactMethod
  fun isLocationEnabled(p: Promise) {
    p.resolve(isLocationEnabled)
  }

  @get:ReactMethod
  val isHeadphonesConnected: Boolean
    get() {
      val audioManager: AudioManager =
        reactApplicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
      return audioManager.isWiredHeadsetOn || audioManager.isBluetoothA2dpOn
    }

  @ReactMethod
  fun isHeadphonesConnected(p: Promise) {
    p.resolve(isHeadphonesConnected)
  }

  @get:ReactMethod
  val availableLocationProviders: WritableMap
    get() {
      val mLocationManager: LocationManager =
        reactApplicationContext.getSystemService(Context.LOCATION_SERVICE) as LocationManager
      val providersAvailability: WritableMap = Arguments.createMap()
      try {
        val providers: List<String> = mLocationManager.getProviders(false)
        for (provider: String? in providers) {
          providersAvailability.putBoolean(
            (provider)!!,
            mLocationManager.isProviderEnabled((provider))
          )
        }
      } catch (e: Exception) {
        System.err.println("Unable to get location providers. LocationManager was null")
      }
      return providersAvailability
    }

  @ReactMethod
  fun getAvailableLocationProviders(p: Promise) {
    p.resolve(availableLocationProviders)
  }

  @get:ReactMethod
  val installReferrer: String?
    get() {
      val sharedPref: SharedPreferences = getTurboDeviceSharedPreferences(
        reactApplicationContext
      )
      return sharedPref.getString("installReferrer", Build.UNKNOWN)
    }

  @ReactMethod
  fun getInstallReferrer(p: Promise) {
    p.resolve(installReferrer)
  }

  @get:Throws(Exception::class)
  private val packageInfo: PackageInfo
    get() {
      return reactApplicationContext.packageManager.getPackageInfo(
        reactApplicationContext.packageName,
        0
      )
    }

  @get:ReactMethod
  val installerPackageName: String
    get() {
      val packageName: String = reactApplicationContext.packageName
      return reactApplicationContext.packageManager.getInstallerPackageName(packageName)
        ?: return "unknown"
    }

  @ReactMethod
  fun getInstallerPackageName(p: Promise) {
    p.resolve(installerPackageName)
  }

  @get:ReactMethod
  val firstInstallTime: Double
    get() {
      return try {
        packageInfo.firstInstallTime.toDouble()
      } catch (e: Exception) {
        (-1).toDouble()
      }
    }

  @ReactMethod
  fun getFirstInstallTime(p: Promise) {
    p.resolve(firstInstallTime)
  }

  @get:ReactMethod
  val lastUpdateTime: Double
    get() {
      return try {
        packageInfo.lastUpdateTime.toDouble()
      } catch (e: Exception) {
        (-1).toDouble()
      }
    }

  @ReactMethod
  fun getLastUpdateTime(p: Promise) {
    p.resolve(lastUpdateTime)
  }

  @get:ReactMethod
  val deviceName: String
    get() {
      try {
        if (Build.VERSION.SDK_INT <= 31) {
          val bluetoothName: String? = Secure.getString(
            reactApplicationContext.contentResolver, "bluetooth_name"
          )
          if (bluetoothName != null) {
            return bluetoothName
          }
        }
        if (Build.VERSION.SDK_INT >= 25) {
          val deviceName: String? = Settings.Global.getString(
            reactApplicationContext.contentResolver, Settings.Global.DEVICE_NAME
          )
          if (deviceName != null) {
            return deviceName
          }
        }
      } catch (e: Exception) {
        // same as default unknown return
      }
      return "unknown"
    }

  @ReactMethod
  fun getDeviceName(p: Promise) {
    p.resolve(deviceName)
  }

  @get:ReactMethod
  @get:SuppressLint("HardwareIds", "MissingPermission")
  val serialNumber: String
    get() {
      try {
        return if (Build.VERSION.SDK_INT >= 26) {
          Build.getSerial()
        } else {
          Build.SERIAL
        }
      } catch (e: Exception) {
        System.err.println("getSerialNumber failed, it probably should not be used: " + e.message)
      }
      return "unknown"
    }

  @ReactMethod
  fun getSerialNumber(p: Promise) {
    p.resolve(serialNumber)
  }

  @get:ReactMethod
  val device: String
    get() {
      return Build.DEVICE
    }

  @ReactMethod
  fun getDevice(p: Promise) {
    p.resolve(device)
  }

  @get:ReactMethod
  val buildId: String
    get() {
      return Build.ID
    }

  @ReactMethod
  fun getBuildId(p: Promise) {
    p.resolve(buildId)
  }

  @get:ReactMethod
  val apiLevel: Int
    get() {
      return Build.VERSION.SDK_INT
    }

  @ReactMethod
  fun getApiLevel(p: Promise) {
    p.resolve(apiLevel)
  }

  @get:ReactMethod
  val bootloader: String
    get() {
      return Build.BOOTLOADER
    }

  @ReactMethod
  fun getBootloader(p: Promise) {
    p.resolve(bootloader)
  }

  @get:ReactMethod
  val display: String
    get() {
      return Build.DISPLAY
    }

  @ReactMethod
  fun getDisplay(p: Promise) {
    p.resolve(display)
  }

  @get:ReactMethod
  val fingerprint: String
    get() {
      return Build.FINGERPRINT
    }

  @ReactMethod
  fun getFingerprint(p: Promise) {
    p.resolve(fingerprint)
  }

  @get:ReactMethod
  val hardware: String
    get() {
      return Build.HARDWARE
    }

  @ReactMethod
  fun getHardware(p: Promise) {
    p.resolve(hardware)
  }

  @get:ReactMethod
  val host: String
    get() {
      return Build.HOST
    }

  @ReactMethod
  fun getHost(p: Promise) {
    p.resolve(host)
  }

  @get:ReactMethod
  val product: String
    get() {
      return Build.PRODUCT
    }

  @ReactMethod
  fun getProduct(p: Promise) {
    p.resolve(product)
  }

  @get:ReactMethod
  val tags: String
    get() {
      return Build.TAGS
    }

  @ReactMethod
  fun getTags(p: Promise) {
    p.resolve(tags)
  }

  @get:ReactMethod
  val type: String
    get() {
      return Build.TYPE
    }

  @ReactMethod
  fun getType(p: Promise) {
    p.resolve(type)
  }

  @get:ReactMethod
  val systemManufacturer: String
    get() {
      return Build.MANUFACTURER
    }

  @ReactMethod
  fun getSystemManufacturer(p: Promise) {
    p.resolve(systemManufacturer)
  }

  @get:ReactMethod
  val codename: String
    get() {
      return Build.VERSION.CODENAME
    }

  @ReactMethod
  fun getCodename(p: Promise) {
    p.resolve(codename)
  }

  @get:ReactMethod
  val incremental: String
    get() {
      return Build.VERSION.INCREMENTAL
    }

  @ReactMethod
  fun getIncremental(p: Promise) {
    p.resolve(incremental)
  }

  @get:ReactMethod
  @get:SuppressLint("HardwareIds")
  val uniqueId: String
    get() {
      return Secure.getString(reactApplicationContext.contentResolver, Secure.ANDROID_ID)
    }

  @ReactMethod
  fun getUniqueId(p: Promise) {
    p.resolve(uniqueId)
  }

  @get:ReactMethod
  @get:SuppressLint("HardwareIds")
  val androidId: String
    get() {
      return uniqueId
    }

  @ReactMethod
  fun getAndroidId(p: Promise) {
    p.resolve(androidId)
  }

  @get:ReactMethod
  val maxMemory: Double
    get() {
      return Runtime.getRuntime().maxMemory().toDouble()
    }

  @ReactMethod
  fun getMaxMemory(p: Promise) {
    p.resolve(maxMemory)
  }

  @get:ReactMethod
  val totalMemory: Double
    get() {
      val actMgr: ActivityManager =
        reactApplicationContext.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
      val memInfo: ActivityManager.MemoryInfo = ActivityManager.MemoryInfo()
      actMgr.getMemoryInfo(memInfo)
      return memInfo.totalMem.toDouble()
    }

  @ReactMethod
  fun getTotalMemory(p: Promise) {
    p.resolve(totalMemory)
  }

  @get:ReactMethod
  val instanceId: String?
    get() {
      return deviceIdResolver.instanceIdSync
    }

  @ReactMethod
  fun getInstanceId(p: Promise) {
    p.resolve(instanceId)
  }

  @get:ReactMethod
  val baseOs: String
    get() {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        return Build.VERSION.BASE_OS
      }
      return "unknown"
    }

  @ReactMethod
  fun getBaseOs(p: Promise) {
    p.resolve(baseOs)
  }

  @get:ReactMethod
  val previewSdkInt: String
    get() {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        return Build.VERSION.PREVIEW_SDK_INT.toString()
      }
      return "unknown"
    }

  @ReactMethod
  fun getPreviewSdkInt(p: Promise) {
    p.resolve(previewSdkInt)
  }

  @get:ReactMethod
  val securityPatch: String
    get() {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        return Build.VERSION.SECURITY_PATCH
      }
      return "unknown"
    }

  @ReactMethod
  fun getSecurityPatch(p: Promise) {
    p.resolve(securityPatch)
  }

  @get:ReactMethod
  val userAgent: String?
    get() {
      return try {
        WebSettings.getDefaultUserAgent(reactApplicationContext)
      } catch (e: RuntimeException) {
        System.getProperty("http.agent")?.toString()
      }
    }

  @ReactMethod
  fun getUserAgent(p: Promise) {
    p.resolve(userAgent)
  }

  @get:ReactMethod
  @get:SuppressLint("HardwareIds", "MissingPermission")
  val phoneNumber: String
    get() {
      if (reactApplicationContext != null && ((reactApplicationContext.checkCallingOrSelfPermission(
          Manifest.permission.READ_PHONE_STATE
        ) == PackageManager.PERMISSION_GRANTED) ||
          (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && reactApplicationContext.checkCallingOrSelfPermission(
            Manifest.permission.READ_SMS
          ) == PackageManager.PERMISSION_GRANTED))
      ) {
        val telMgr: TelephonyManager =
          reactApplicationContext.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        try {
          return telMgr.line1Number
        } catch (e: SecurityException) {
          System.err.println("getLine1Number called with permission, but threw anyway: " + e.message)
        }
      }
      return "unknown"
    }

  @ReactMethod
  fun getPhoneNumber(p: Promise) {
    p.resolve(phoneNumber)
  }

  @get:ReactMethod
  val supportedAbis: WritableArray
    get() {
      val array: WritableArray = WritableNativeArray()
      for (abi: String? in Build.SUPPORTED_ABIS) {
        array.pushString(abi)
      }
      return array
    }

  @ReactMethod
  fun getSupportedAbis(p: Promise) {
    p.resolve(supportedAbis)
  }

  @get:ReactMethod
  val supported32BitAbis: WritableArray
    get() {
      val array: WritableArray = WritableNativeArray()
      for (abi: String? in Build.SUPPORTED_32_BIT_ABIS) {
        array.pushString(abi)
      }
      return array
    }

  @ReactMethod
  fun getSupported32BitAbis(p: Promise) {
    p.resolve(supported32BitAbis)
  }

  @get:ReactMethod
  val supported64BitAbis: WritableArray
    get() {
      val array: WritableArray = WritableNativeArray()
      for (abi: String? in Build.SUPPORTED_64_BIT_ABIS) {
        array.pushString(abi)
      }
      return array
    }

  @ReactMethod
  fun getSupported64BitAbis(p: Promise) {
    p.resolve(supported64BitAbis)
  }

  private fun getPowerStateFromIntent(intent: Intent?): WritableMap? {
    if (intent == null) {
      return null
    }
    val batteryLevel: Int = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
    val batteryScale: Int = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
    val isPlugged: Int = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
    val status: Int = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
    val batteryPercentage: Float = batteryLevel / batteryScale.toFloat()
    var batteryState: String? = "unknown"
    if (isPlugged == 0) {
      batteryState = "unplugged"
    } else if (status == BatteryManager.BATTERY_STATUS_CHARGING) {
      batteryState = "charging"
    } else if (status == BatteryManager.BATTERY_STATUS_FULL) {
      batteryState = "full"
    }
    val powerManager =
      reactApplicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager
    val powerSaveMode: Boolean = powerManager.isPowerSaveMode
    val powerState: WritableMap = Arguments.createMap()
    powerState.putString(BATTERY_STATE, batteryState)
    powerState.putDouble(BATTERY_LEVEL, batteryPercentage.toDouble())
    powerState.putBoolean(LOW_POWER_MODE, powerSaveMode)
    return powerState
  }

  private fun sendEvent(
    reactContext: ReactContext,
    eventName: String,
    data: Any?
  ) {
    reactContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
      .emit(eventName, data)
  }

  companion object {
    const val NAME: String = "ReactNativeTurboDevice"
    private const val BATTERY_STATE: String = "batteryState"
    private const val BATTERY_LEVEL: String = "batteryLevel"
    private const val LOW_POWER_MODE: String = "lowPowerMode"
    fun getTurboDeviceSharedPreferences(context: Context): SharedPreferences {
      return context.getSharedPreferences("react-native-device-info", Context.MODE_PRIVATE)
    }
  }
}
