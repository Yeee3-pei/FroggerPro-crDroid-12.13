/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package com.froggerpro.privacy;

import android.os.Bundle;
import android.os.SystemProperties;
import android.preference.EditTextPreference;
import android.preference.ListPreference;
import android.preference.Preference;
import android.preference.PreferenceActivity;
import android.preference.SwitchPreference;
import android.provider.DeviceConfig;
import android.provider.Settings;
import android.widget.Toast;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * FroggerPro privacy settings: pure runtime switches (class A) plus read-only status rows.
 * Each switch writes one real system setting; defaults target the strongest privacy.
 */
public class PrivacySettingsActivity extends PreferenceActivity {

    // ---- Tier ----
    private static final String KEY_TIER = "tier";

    // ---- Existing switches ----
    private static final String KEY_CAPTIVE_OFF = "captive_portal_off";
    private static final String KEY_DNS_ON = "private_dns_on";
    private static final String KEY_DNS_HOST = "private_dns_host";
    private static final String KEY_AGPS_OFF = "agps_off";
    private static final String KEY_ADB_OFF = "adb_off";
    private static final String KEY_ADSERVICES_OFF = "adservices_off";
    private static final String KEY_LOGCATD_STATUS = "logcatd_status";

    // ---- Class A switches ----
    private static final String KEY_LOCATION_ON = "location_on";
    private static final String KEY_LOCATION_ACCURACY = "location_accuracy";
    private static final String KEY_NFC_OFF = "nfc_off";
    private static final String KEY_WIFI_SCAN_OFF = "wifi_scan_off";
    private static final String KEY_BLE_SCAN_OFF = "ble_scan_off";
    private static final String KEY_SENSOR_PRIVACY_OPEN = "sensor_privacy_open";
    private static final String KEY_APP_LANGUAGE = "app_language";
    private static final String KEY_NTP_SERVER = "ntp_server";
    private static final String KEY_AUTO_TIME_OFF = "auto_time_off";

    // ---- System setting keys ----
    private static final String DNS_MODE_GLOBAL = "private_dns_mode";
    private static final String DNS_SPECIFIER_GLOBAL = "private_dns_specifier";

    /** Location mode: 0=off / 1=device only (no network location) / 3=high accuracy */
    private static final int LOCATION_MODE_OFF = 0;
    private static final int LOCATION_MODE_DEVICE_ONLY = 1;
    private static final int LOCATION_MODE_HIGH_ACCURACY = 3;

    /** Local memory of the accuracy the user picked; the system setting stays the source of truth. */
    private static final String PREFS_NAME = "privacy_prefs";
    private static final String PREF_LOCATION_ACCURACY = "location_accuracy";

    /** DeviceConfig: advertising framework namespace and key (key names from FlagsConstants / PhFlags) */
    private static final String AD_NAMESPACE = "adservices";
    private static final String AD_KEY = "adservice_enabled";

    /** Persistent logcatd property (for read-only display) */
    private static final String PROP_LOGPERSISTD = "persist.logd.logpersistd";
    // persist.sys.xtra-daemon.enabled is not read: platform_app cannot read it (avc denied); only AVC noise.

    private static final String LOGPERSISTD_SEPOLICY_HINT =
            "set_prop(system_app, logpersistd_logging_prop)";

    // ---- Class N: LineageOS stats reporting ----
    // stats_collection is served by content://lineagesettings/secure, NOT AOSP Settings.Secure.
    private static final String KEY_STATS_OFF = "stats_off";
    private static final String LINEAGE_SECURE_URI = "content://lineagesettings/secure";

    private ListPreference mTier;
    private SwitchPreference mAgpsOff;
    private SwitchPreference mAdbOff;
    private SwitchPreference mCaptiveOff;
    private SwitchPreference mDnsOn;
    private EditTextPreference mDnsHost;
    private SwitchPreference mAdservicesOff;
    private Preference mLogcatdStatus;
    private SwitchPreference mLocationOn;
    private ListPreference mLocationAccuracy;
    private SwitchPreference mNfcOff;
    private SwitchPreference mWifiScanOff;
    private SwitchPreference mBleScanOff;
    private Preference mSensorPrivacyOpen;
    private EditTextPreference mNtpServer;
    private SwitchPreference mAutoTimeOff;
    private SwitchPreference mStatsOff;

    @Override
    @SuppressWarnings("deprecation")
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        addPreferencesFromResource(R.xml.privacy_prefs);

        mTier = (ListPreference) findPreference(KEY_TIER);
        mAgpsOff = (SwitchPreference) findPreference(KEY_AGPS_OFF);
        mAdbOff = (SwitchPreference) findPreference(KEY_ADB_OFF);

        // Returns false on write failure, so the UI does not pretend the change succeeded.
        mStatsOff = (SwitchPreference) findPreference(KEY_STATS_OFF);
        if (mStatsOff != null) {
            mStatsOff.setOnPreferenceChangeListener((p, v) -> {
                boolean off = (Boolean) v;
                // Read back immediately after writing: only change the UI if it really landed.
                return setLineageSecureInt("stats_collection", off ? 0 : 1)
                        && getLineageSecureInt("stats_collection", 1) == (off ? 0 : 1);
            });
        }

        // Sends the user to the platform privacy dashboard instead of hand-rolling a per-app list.
        Preference dash = findPreference("privacy_dashboard");
        if (dash != null) {
            dash.setOnPreferenceClickListener(p -> {
                final String[] actions = {
                        "android.settings.PRIVACY_SETTINGS",
                        "android.settings.PRIVACY_DASHBOARD",
                        "android.settings.MANAGE_APPLICATIONS_SETTINGS",
                        "android.settings.APPLICATION_SETTINGS"
                };
                for (String a : actions) {
                    try {
                        startActivity(new android.content.Intent(a)
                                .addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK));
                        return true;   // Sent is enough; do not assume it will definitely open.
                    } catch (Exception ignore) {
                        // This action does not exist, so try the next one.
                    }
                }
                Toast.makeText(this, R.string.privacy_dashboard_unavailable,
                        Toast.LENGTH_LONG).show();
                return true;
            });
        }
        mCaptiveOff = (SwitchPreference) findPreference(KEY_CAPTIVE_OFF);
        mDnsOn = (SwitchPreference) findPreference(KEY_DNS_ON);
        mDnsHost = (EditTextPreference) findPreference(KEY_DNS_HOST);
        mAdservicesOff = (SwitchPreference) findPreference(KEY_ADSERVICES_OFF);
        mLogcatdStatus = findPreference(KEY_LOGCATD_STATUS);
        mLocationOn = (SwitchPreference) findPreference(KEY_LOCATION_ON);
        mLocationAccuracy = (ListPreference) findPreference(KEY_LOCATION_ACCURACY);
        mNfcOff = (SwitchPreference) findPreference(KEY_NFC_OFF);
        mWifiScanOff = (SwitchPreference) findPreference(KEY_WIFI_SCAN_OFF);
        mBleScanOff = (SwitchPreference) findPreference(KEY_BLE_SCAN_OFF);
        mSensorPrivacyOpen = findPreference(KEY_SENSOR_PRIVACY_OPEN);
        mNtpServer = (EditTextPreference) findPreference(KEY_NTP_SERVER);
        mAutoTimeOff = (SwitchPreference) findPreference(KEY_AUTO_TIME_OFF);

        if (mTier != null) {
            mTier.setOnPreferenceChangeListener((p, v) -> {
                applyTier(String.valueOf(v));
                return true;
            });
        }

        if (mAgpsOff != null) {
            mAgpsOff.setOnPreferenceChangeListener((p, v) -> {
                if (!setAgpsDisabled((Boolean) v)) {
                    toast(getString(R.string.agps_write_failed));
                }
                return true;
            });
        }

        if (mAdbOff != null) {
            mAdbOff.setOnPreferenceChangeListener((p, v) -> {
                if (!setAdbDisabled((Boolean) v)) {
                    toast(getString(R.string.adb_write_failed));
                }
                return true;
            });
        }

        if (mCaptiveOff != null) {
            mCaptiveOff.setOnPreferenceChangeListener((p, v) -> {
                setCaptivePortalDisabled((Boolean) v);
                return true;
            });
        }

        if (mDnsOn != null) {
            mDnsOn.setOnPreferenceChangeListener((p, v) -> {
                setPrivateDns((Boolean) v);
                return true;
            });
        }

        if (mDnsHost != null) {
            mDnsHost.setOnPreferenceChangeListener((p, v) -> {
                setDnsHost(String.valueOf(v));
                return true;
            });
        }

        if (mAdservicesOff != null) {
            mAdservicesOff.setOnPreferenceChangeListener((p, v) -> {
                if (!setAdServicesDisabled((Boolean) v)) {
                    toast(getString(R.string.adservices_write_failed));
                    syncFromSystem();
                }
                return true;
            });
        }

        if (mLocationOn != null) {
            mLocationOn.setOnPreferenceChangeListener((p, v) -> {
                int mode = (Boolean) v ? readAccuracyPref() : LOCATION_MODE_OFF;
                if (!setLocationMode(mode)) {
                    toast(getString(R.string.location_mode_write_failed));
                }
                syncFromSystem();
                return true;
            });
        }

        if (mLocationAccuracy != null) {
            mLocationAccuracy.setOnPreferenceChangeListener((p, v) -> {
                int mode = Integer.parseInt(String.valueOf(v));
                saveAccuracyPref(mode);
                // Write immediately, but only while the location switch is on.
                if (mLocationOn != null && mLocationOn.isChecked() && !setLocationMode(mode)) {
                    toast(getString(R.string.location_accuracy_write_failed));
                }
                syncFromSystem();
                return true;
            });
        }

        if (mNfcOff != null) {
            mNfcOff.setOnPreferenceChangeListener((p, v) -> {
                if (!setNfcDisabled((Boolean) v)) {
                    toast(getString(R.string.nfc_write_failed));
                }
                syncFromSystem();
                return true;
            });
        }

        if (mWifiScanOff != null) {
            mWifiScanOff.setOnPreferenceChangeListener((p, v) -> {
                if (!setGlobalInt("wifi_scan_always_enabled", !(Boolean) v ? 1 : 0)) {
                    toast(getString(R.string.wifi_scan_write_failed));
                }
                syncFromSystem();
                return true;
            });
        }

        if (mBleScanOff != null) {
            mBleScanOff.setOnPreferenceChangeListener((p, v) -> {
                if (!setGlobalInt("ble_scan_always_enabled", !(Boolean) v ? 1 : 0)) {
                    toast(getString(R.string.ble_scan_write_failed));
                }
                syncFromSystem();
                return true;
            });
        }

        // The platform owns the camera/microphone master switch; this app cannot hold
        // MANAGE_SENSOR_PRIVACY (protectionLevel = internal|installer|role), so it only opens
        // the system privacy screen instead of pretending to toggle it.
        if (mSensorPrivacyOpen != null) {
            mSensorPrivacyOpen.setOnPreferenceClickListener(p -> {
                startActivity(new android.content.Intent(
                        android.provider.Settings.ACTION_PRIVACY_SETTINGS));
                return true;
            });
        }

        Preference appLanguage = findPreference(KEY_APP_LANGUAGE);
        if (appLanguage != null) {
            // Per-app language: the platform page lists the locales declared in locales_config.xml.
            appLanguage.setOnPreferenceClickListener(p -> {
                startActivity(new android.content.Intent(Settings.ACTION_APP_LOCALE_SETTINGS,
                        android.net.Uri.fromParts("package", getPackageName(), null)));
                return true;
            });
        }

        if (mNtpServer != null) {
            mNtpServer.setOnPreferenceChangeListener((p, v) -> {
                String host = String.valueOf(v).trim();
                try {
                    Settings.Global.putString(getContentResolver(),
                            Settings.Global.NTP_SERVER, host.isEmpty() ? null : host);
                } catch (Exception e) {
                    toast(getString(R.string.ntp_server_error, e.getClass().getSimpleName()));
                }
                toast(getString(R.string.ntp_server_set));
                syncFromSystem();
                return true;
            });
        }

        if (mAutoTimeOff != null) {
            mAutoTimeOff.setOnPreferenceChangeListener((p, v) -> {
                boolean auto = !(Boolean) v;
                boolean ok = setGlobalInt("auto_time", auto ? 1 : 0)
                        & setGlobalInt("auto_time_zone", auto ? 1 : 0);
                if (!ok) {
                    toast(getString(R.string.auto_time_write_failed));
                }
                syncFromSystem();
                return true;
            });
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        syncFromSystem();
    }

    /** Back-fill the UI from the real system values (not from SharedPreferences, so what is shown is the true state). */
    @SuppressWarnings("deprecation")
    private void syncFromSystem() {
        int cpMode = Settings.Global.getInt(getContentResolver(),
                Settings.Global.CAPTIVE_PORTAL_MODE, Settings.Global.CAPTIVE_PORTAL_MODE_PROMPT);
        String dnsMode = Settings.Global.getString(getContentResolver(), DNS_MODE_GLOBAL);
        String dnsSpec = Settings.Global.getString(getContentResolver(), DNS_SPECIFIER_GLOBAL);

        int agps = Settings.Global.getInt(getContentResolver(),
                Settings.Global.ASSISTED_GPS_ENABLED, 0);
        if (mAgpsOff != null) {
            mAgpsOff.setChecked(agps == 0);
            // Only assisted_gps_enabled is shown; persist.sys.xtra-daemon.enabled is unreadable (avc denied).
            mAgpsOff.setSummary(getString(R.string.agps_summary)
                    + "\nCurrent assisted_gps_enabled=" + agps
                    + getString(R.string.agps_value_note));
        }

        int adb = Settings.Global.getInt(getContentResolver(), Settings.Global.ADB_ENABLED, 0);
        if (mAdbOff != null) {
            mAdbOff.setChecked(adb == 0);
            mAdbOff.setSummary(getString(R.string.adb_summary)
                    + "\nCurrent adb_enabled=" + adb);
        }

        if (mAdservicesOff != null) {
            Boolean adsDisabled = readAdServicesDisabled();
            if (adsDisabled == null) {
                mAdservicesOff.setChecked(true);
                mAdservicesOff.setEnabled(false);
                mAdservicesOff.setSummary(getString(R.string.adservices_summary)
                        + getString(R.string.adservices_unreadable)
                        + "\nConfirm with an adb command: adb shell device_config get "
                        + AD_NAMESPACE + " " + AD_KEY);
            } else {
                mAdservicesOff.setEnabled(true);
                mAdservicesOff.setChecked(adsDisabled);
                mAdservicesOff.setSummary(getString(R.string.adservices_summary)
                        + "\nCurrent adservice_enabled=" + (!adsDisabled));
            }
        }

        if (mLogcatdStatus != null) {
            String v = readProp(PROP_LOGPERSISTD);
            // ---- Class N: LineageOS stats reporting, current value ----
            if (mStatsOff != null) {
                int sc = getLineageSecureInt("stats_collection", 1);
                mStatsOff.setChecked(sc == 0);   // value 0 = disabled, so the switch shows ON.
                mStatsOff.setSummary("stats_collection=" + sc
                        + getString(sc == 0 ? R.string.stats_disabled : R.string.stats_on_recommend_off)
                        + getString(R.string.stats_tree_default_note));
            }

            String shown = (v == null || v.isEmpty()) ? getString(R.string.logpersistd_empty_note) : v;
            mLogcatdStatus.setSummary(getString(R.string.logcatd_summary)
                    + "\nCurrent persist.logd.logpersistd=" + shown
                    + "\nVerify: adb shell getprop " + PROP_LOGPERSISTD
                    + getString(R.string.logpersistd_readonly_note, LOGPERSISTD_SEPOLICY_HINT));
        }

        if (mCaptiveOff != null) {
            mCaptiveOff.setChecked(cpMode == 0);
            mCaptiveOff.setSummary(getString(R.string.captive_portal_summary)
                    + "\nVerify: adb shell settings get global captive_portal_mode  (current: " + cpMode + ")");
        }

        if (mDnsOn != null) {
            mDnsOn.setSummary(getString(R.string.private_dns_summary)
                    + "\nVerify: adb shell settings get global " + DNS_MODE_GLOBAL
                    + "  (current: " + (dnsMode == null ? "unset" : dnsMode) + ")");
            mDnsOn.setChecked("hostname".equals(dnsMode) || "opportunistic".equals(dnsMode));
        }

        if (mDnsHost != null) mDnsHost.setText(dnsSpec == null ? "" : dnsSpec);

        // ---- Location (class A): on/off switch plus an accuracy list ----
        int locMode = Settings.Secure.getInt(getContentResolver(),
                Settings.Secure.LOCATION_MODE, LOCATION_MODE_OFF);
        boolean locationOn = locMode != LOCATION_MODE_OFF;
        if (mLocationOn != null) {
            mLocationOn.setChecked(locationOn);
            mLocationOn.setSummary(getString(R.string.location_summary)
                    + "\nCurrent location_mode=" + locMode
                    + getString(R.string.location_mode_note)
                    + "\nVerify: adb shell settings get secure location_mode");
        }
        if (mLocationAccuracy != null) {
            // The accuracy list only makes sense while location is on.
            mLocationAccuracy.setEnabled(locationOn);
            if (locationOn) {
                // Mode 2 (battery saving) is not offered; any non-high-accuracy mode maps to device only.
                mLocationAccuracy.setValue(String.valueOf(
                        locMode == LOCATION_MODE_HIGH_ACCURACY ? LOCATION_MODE_HIGH_ACCURACY
                                                               : LOCATION_MODE_DEVICE_ONLY));
            }
        }

        // ---- NFC (class A) ----
        int nfc = Settings.Global.getInt(getContentResolver(), "nfc_on", 1);
        if (mNfcOff != null) {
            mNfcOff.setChecked(nfc == 0);
            mNfcOff.setSummary(getString(R.string.nfc_summary)
                    + "\nCurrent nfc_on=" + nfc
                    + "\nVerify: adb shell settings get global nfc_on");
        }

        // ---- Wi-Fi/Bluetooth always scan (class A) ----
        int wifiScan = Settings.Global.getInt(getContentResolver(),
                Settings.Global.WIFI_SCAN_ALWAYS_AVAILABLE, 0);
        if (mWifiScanOff != null) {
            mWifiScanOff.setChecked(wifiScan == 0);
            mWifiScanOff.setSummary(getString(R.string.wifi_scan_summary)
                    + "\nCurrent wifi_scan_always_enabled=" + wifiScan
                    + "\nVerify: adb shell settings get global wifi_scan_always_enabled");
        }

        int bleScan = Settings.Global.getInt(getContentResolver(),
                Settings.Global.BLE_SCAN_ALWAYS_AVAILABLE, 0);
        if (mBleScanOff != null) {
            mBleScanOff.setChecked(bleScan == 0);
            mBleScanOff.setSummary(getString(R.string.ble_scan_summary)
                    + "\nCurrent ble_scan_always_enabled=" + bleScan
                    + "\nVerify: adb shell settings get global ble_scan_always_enabled");
        }

        // ---- NTP (class A; may require a reboot) ----
        if (mNtpServer != null) {
            String ntp = Settings.Global.getString(getContentResolver(), Settings.Global.NTP_SERVER);
            mNtpServer.setSummary(getString(R.string.ntp_summary)
                    + "\nCurrent ntp_server=" + (ntp == null || ntp.isEmpty() ? "(unset)" : ntp)
                    + "\nVerify: adb shell settings get global ntp_server"
                    + getString(R.string.ntp_reboot_note));
            mNtpServer.setText(ntp == null ? "" : ntp);
        }

        // ---- Auto time/timezone (class A) ----
        int autoTime = Settings.Global.getInt(getContentResolver(),
                Settings.Global.AUTO_TIME, 1);
        int autoTz = Settings.Global.getInt(getContentResolver(),
                Settings.Global.AUTO_TIME_ZONE, 1);
        if (mAutoTimeOff != null) {
            mAutoTimeOff.setChecked(autoTime == 0 && autoTz == 0);
            mAutoTimeOff.setSummary(getString(R.string.auto_time_summary)
                    + "\nCurrent auto_time=" + autoTime + " / auto_time_zone=" + autoTz
                    + "\nVerify: adb shell settings get global auto_time");
        }
    }

    // =====================================================================
    //  Class A: pure runtime switches
    // =====================================================================

    private boolean setAgpsDisabled(boolean disabled) {
        try {
            Settings.Global.putInt(getContentResolver(),
                    Settings.Global.ASSISTED_GPS_ENABLED, disabled ? 0 : 1);
            return true;
        } catch (Exception e) {
            toast(getString(R.string.agps_error, e.getClass().getSimpleName()));
            return false;
        }
    }

    private boolean setAdbDisabled(boolean disabled) {
        try {
            Settings.Global.putInt(getContentResolver(),
                    Settings.Global.ADB_ENABLED, disabled ? 0 : 1);
            return true;
        } catch (Exception e) {
            toast(getString(R.string.adb_error, e.getClass().getSimpleName()));
            return false;
        }
    }

    /** Reads LineageSettings (a DIFFERENT provider from AOSP's Settings.Secure). */
    private int getLineageSecureInt(String name, int def) {
        try (android.database.Cursor c = getContentResolver().query(
                android.net.Uri.parse(LINEAGE_SECURE_URI),
                new String[]{"value"}, "name=?", new String[]{name}, null)) {
            if (c != null && c.moveToFirst()) {
                String v = c.getString(0);
                if (v != null) {
                    return Integer.parseInt(v.trim());
                }
            }
        } catch (Exception e) {
            // On read failure return the default, so a single failure does not crash the app.
        }
        return def;
    }

    /** Writes LineageSettings; returns whether an exception was thrown (real success is verified by the caller reading back). */
    private boolean setLineageSecureInt(String name, int value) {
        try {
            android.content.ContentValues cv = new android.content.ContentValues();
            cv.put("name", name);
            cv.put("value", String.valueOf(value));
            getContentResolver().insert(android.net.Uri.parse(LINEAGE_SECURE_URI), cv);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /** Generic: write an integer to Settings.Global (returns whether it succeeded). */
    private boolean setGlobalInt(String key, int value) {
        try {
            Settings.Global.putInt(getContentResolver(), key, value);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /** Writes a location_mode value: 0=off / 1=device only / 3=high accuracy. */
    private boolean setLocationMode(int mode) {
        try {
            Settings.Secure.putInt(getContentResolver(), Settings.Secure.LOCATION_MODE, mode);
            return true;
        } catch (Exception e) {
            toast(getString(R.string.location_mode_error, e.getClass().getSimpleName()));
            return false;
        }
    }

    /** The accuracy the user last picked; the real value still comes from the system setting. */
    private int readAccuracyPref() {
        return getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                .getInt(PREF_LOCATION_ACCURACY, LOCATION_MODE_HIGH_ACCURACY);
    }

    private void saveAccuracyPref(int mode) {
        getSharedPreferences(PREFS_NAME, MODE_PRIVATE).edit()
                .putInt(PREF_LOCATION_ACCURACY, mode).apply();
    }

    private boolean setNfcDisabled(boolean disabled) {
        return setGlobalInt("nfc_on", disabled ? 0 : 1);
    }

    // =====================================================================
    //  Advertising framework (DeviceConfig)
    // =====================================================================

    private Boolean readAdServicesDisabled() {
        try {
            boolean enabled = DeviceConfig.getBoolean(AD_NAMESPACE, AD_KEY, false);
            return !enabled;
        } catch (Throwable t) {
            // Fall through to the fallback path
        }
        String v = execDeviceConfig("get", AD_NAMESPACE, AD_KEY);
        if (v == null) return null;
        return !"true".equals(v);
    }

    private boolean setAdServicesDisabled(boolean disabled) {
        String value = disabled ? "false" : "true";
        try {
            if (DeviceConfig.setProperty(AD_NAMESPACE, AD_KEY, value, false)) {
                return true;
            }
        } catch (Throwable t) {
            // Fall through to the fallback path
        }
        String r = execDeviceConfig("put", AD_NAMESPACE, AD_KEY, value);
        if (r == null) return false;
        Boolean now = readAdServicesDisabled();
        return now != null && now == disabled;
    }

    private String execDeviceConfig(String... args) {
        try {
            List<String> cmd = new ArrayList<>();
            cmd.add("/system/bin/device_config");
            for (String a : args) cmd.add(a);
            ProcessBuilder pb = new ProcessBuilder(cmd);
            pb.redirectErrorStream(true);
            Process p = pb.start();
            StringBuilder out = new StringBuilder();
            try (BufferedReader r =
                         new BufferedReader(new InputStreamReader(p.getInputStream()))) {
                String line;
                while ((line = r.readLine()) != null) out.append(line.trim());
            }
            p.waitFor(3, TimeUnit.SECONDS);
            return out.toString();
        } catch (Throwable t) {
            return null;
        }
    }

    private String readProp(String key) {
        try {
            return SystemProperties.get(key, "");
        } catch (Throwable t) {
            return "";
        }
    }

    private void setCaptivePortalDisabled(boolean disabled) {
        try {
            Settings.Global.putInt(getContentResolver(), Settings.Global.CAPTIVE_PORTAL_MODE,
                    disabled ? 0 : Settings.Global.CAPTIVE_PORTAL_MODE_PROMPT);
        } catch (Exception e) {
            toast(getString(R.string.captive_portal_error, e.getClass().getSimpleName()));
        }
        syncFromSystem();
    }

    private void setPrivateDns(boolean enabled) {
        try {
            String mode = enabled ? "hostname" : "off";
            String spec = Settings.Global.getString(getContentResolver(), DNS_SPECIFIER_GLOBAL);
            if (enabled && (spec == null || spec.isEmpty())) {
                mode = "opportunistic";
            }
            Settings.Global.putString(getContentResolver(), DNS_MODE_GLOBAL, mode);
        } catch (Exception e) {
            toast(getString(R.string.private_dns_error, e.getClass().getSimpleName()));
        }
        syncFromSystem();
    }

    private void setDnsHost(String host) {
        try {
            Settings.Global.putString(getContentResolver(), DNS_SPECIFIER_GLOBAL, host);
            if (host != null && !host.isEmpty()) {
                Settings.Global.putString(getContentResolver(), DNS_MODE_GLOBAL, "hostname");
            }
        } catch (Exception e) {
            toast(getString(R.string.dot_hostname_error, e.getClass().getSimpleName()));
        }
        syncFromSystem();
    }

    /**
     * One-tap tier application (minimal / standard / strict / custom); any single failure is listed.
     */
    private void applyTier(String tier) {
        List<String> failed = new ArrayList<>();

        switch (tier) {
            case "standard":
            case "strict": {
                if (!setAgpsDisabled(true)) failed.add("AGPS->0");
                if (!setAdServicesDisabled(true)) failed.add("adservices->0");
                if (!setLocationMode(LOCATION_MODE_DEVICE_ONLY)) failed.add("location->device only");
                saveAccuracyPref(LOCATION_MODE_DEVICE_ONLY);
                if (!setGlobalInt("wifi_scan_always_enabled", 0)) failed.add("WiFi scan->0");
                if (!setGlobalInt("ble_scan_always_enabled", 0)) failed.add("BT scan->0");
                if (!setNfcDisabled(true)) failed.add("NFC->0");
                if ("strict".equals(tier)) {
                    setCaptivePortalDisabled(true);
                    if (!setAdbDisabled(true)) failed.add("adb->0");
                    if (!setGlobalInt("auto_time", 0)) failed.add("auto_time->0");
                    if (!setGlobalInt("auto_time_zone", 0)) failed.add("auto_time_zone->0");
                }
                break;
            }
            case "custom":
                toast(getString(R.string.tier_custom_notice));
                break;
            case "minimal":
            default:
                toast(getString(R.string.tier_minimal_notice));
                break;
        }

        if (!failed.isEmpty()) {
            toast(getString(R.string.tier_failed, tier, String.join(", ", failed)));
        } else if (!"custom".equals(tier) && !"minimal".equals(tier)) {
            toast(getString(R.string.tier_applied, tier));
        }
        syncFromSystem();
    }

    private void toast(String msg) {
        Toast.makeText(this, msg, Toast.LENGTH_LONG).show();
    }
}
