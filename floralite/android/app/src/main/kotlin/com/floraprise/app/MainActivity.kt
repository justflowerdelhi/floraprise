package com.floraprise.app

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID

class MainActivity : FlutterActivity() {
	private val channelName = "floraprise/printer_bluetooth"
	private val sppUuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
	private var socket: BluetoothSocket? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
			when (call.method) {
				"scan" -> scan(result)
				"connect" -> {
					val address = call.argument<String>("address")
					if (address.isNullOrBlank()) {
						result.error("PRINTER_NOT_FOUND", "Bluetooth address is missing", null)
					} else {
						connect(address, result)
					}
				}
				"disconnect" -> {
					disconnectSocket()
					result.success(null)
				}
				"isConnected" -> result.success(socket?.isConnected == true)
				"printBytes" -> {
					val bytes = call.arguments as? ByteArray
					if (bytes == null) {
						result.error("INVALID_BYTES", "Print data is missing", null)
					} else {
						printBytes(bytes, result)
					}
				}
				else -> result.notImplemented()
			}
		}
	}

	@SuppressLint("MissingPermission")
	private fun scan(result: MethodChannel.Result) {
		val adapter = bluetoothAdapter()
		if (adapter == null) {
			result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth is not available on this device", null)
			return
		}
		if (!adapter.isEnabled) {
			result.error("BLUETOOTH_DISABLED", "Bluetooth is disabled", null)
			return
		}
		if (!hasBluetoothPermission()) {
			result.error("BLUETOOTH_PERMISSION_DENIED", "Bluetooth permission is required", null)
			return
		}
		val devices = adapter.bondedDevices
			.filter { it.address?.isNotBlank() == true }
			.map {
				mapOf(
					"name" to ((it.name ?: "Bluetooth Printer")),
					"address" to it.address,
				)
			}
		result.success(devices)
	}

	@SuppressLint("MissingPermission")
	private fun connect(address: String, result: MethodChannel.Result) {
		val adapter = bluetoothAdapter()
		if (adapter == null) {
			result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth is not available on this device", null)
			return
		}
		if (!adapter.isEnabled) {
			result.error("BLUETOOTH_DISABLED", "Bluetooth is disabled", null)
			return
		}
		if (!hasBluetoothPermission()) {
			result.error("BLUETOOTH_PERMISSION_DENIED", "Bluetooth permission is required", null)
			return
		}
		Thread {
			try {
				disconnectSocket()
				val device: BluetoothDevice = adapter.getRemoteDevice(address)
				adapter.cancelDiscovery()
				val newSocket = openPrinterSocket(device)
				socket = newSocket
				runOnUiThread { result.success(true) }
			} catch (error: IllegalArgumentException) {
				runOnUiThread { result.error("PRINTER_NOT_FOUND", "Printer unavailable", null) }
			} catch (error: IOException) {
				disconnectSocket()
				runOnUiThread { result.error("CONNECTION_FAILED", error.message ?: "Connection failed", null) }
			} catch (error: SecurityException) {
				runOnUiThread { result.error("BLUETOOTH_PERMISSION_DENIED", "Bluetooth permission is required", null) }
			}
		}.start()
	}

	@SuppressLint("MissingPermission")
	private fun openPrinterSocket(device: BluetoothDevice): BluetoothSocket {
		var secureSocket: BluetoothSocket? = null
		try {
			secureSocket = device.createRfcommSocketToServiceRecord(sppUuid)
			secureSocket.connect()
			return secureSocket
		} catch (secureError: IOException) {
			try {
				secureSocket?.close()
			} catch (_: IOException) {
			}
			val insecureSocket = device.createInsecureRfcommSocketToServiceRecord(sppUuid)
			insecureSocket.connect()
			return insecureSocket
		}
	}

	private fun printBytes(bytes: ByteArray, result: MethodChannel.Result) {
		Thread {
			try {
				val activeSocket = socket
				if (activeSocket?.isConnected != true) {
					runOnUiThread { result.error("PRINTER_NOT_CONNECTED", "Printer is not connected", null) }
					return@Thread
				}
				val output = activeSocket.outputStream
				output.write(bytes)
				output.flush()
				runOnUiThread { result.success(null) }
			} catch (error: IOException) {
				disconnectSocket()
				runOnUiThread { result.error("CONNECTION_LOST", error.message ?: "Connection lost", null) }
			} catch (error: SecurityException) {
				runOnUiThread { result.error("BLUETOOTH_PERMISSION_DENIED", "Bluetooth permission is required", null) }
			}
		}.start()
	}

	private fun disconnectSocket() {
		try {
			socket?.close()
		} catch (_: IOException) {
		} finally {
			socket = null
		}
	}

	private fun bluetoothAdapter(): BluetoothAdapter? {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
			val manager = getSystemService(BluetoothManager::class.java)
			manager?.adapter
		} else {
			@Suppress("DEPRECATION")
			BluetoothAdapter.getDefaultAdapter()
		}
	}

	private fun hasBluetoothPermission(): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
		return checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
	}
}
