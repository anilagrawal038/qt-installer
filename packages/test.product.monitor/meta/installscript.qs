var dataExtracted = false;

function Component() {
    // constructor
    log("Inside Test Product Monitor Component()");
    component.loaded.connect(this, Component.prototype.loaded);
}

Component.prototype.loaded = function () {
    log("Inside Test Product Monitor Component.prototype.loaded()");
}

Component.prototype.isDefault = function () {
    log("Inside Test Product Monitor  isDefault() systemConfigFilePath : " + installer.value("systemConfigFilePath"));
    log("Inside Test Product Monitor  isDefault() installerInUpgradationMode : " + installer.value("installerInUpgradationMode"));
    if (installer.value("installerInUpgradationMode") == "true" || installer.fileExists(installer.value("systemConfigFilePath"))) {
        if (getConfProperty("test.product.monitor") == "true") {
            return true;
        } else {
            return false;
        }
    } else {
        return true;
    }
}

Component.prototype.dynamicMonitorConfigurationPageEntered = function () {
    log("Inside Test Product Monitor Component.prototype.dynamicMonitorConfigurationPageEntered()");
    // var pageWidget = gui.pageWidgetByObjectName("DynamicMonitorConfigurationPage");
}

Component.prototype.createOperations = function () {
    log("Inside Test Product Monitor Component.prototype.createOperations()");
    try {
        component.createOperations();
    } catch (e) {
        log(e);
    }

    if (installer.value("installerInUpgradationMode") == "true") {
        log("Inside Test Product Monitor Component (Installer mode : Upgrade)");
        upgradeMonitor();
    } else {
        log("Inside Test Product Monitor Component (Installer mode : Install)");
        installMonitor();
        uninstallMonitor();
    }

}

function installMonitor() {
    log("Inside Test Product installMonitor()");
    var destDir = installer.value("TargetDir") + "/Monitor";
}

function uninstallMonitor() {
    log("Register opeartions for uninstallMonitor()");
    var destDir = installer.value("TargetDir") + "/Monitor";
}

function upgradeMonitor() {
    log("Inside upgradeMonitor()");
    var targetDir = installer.value("TargetDir");

}

function getConfProperty(key) {
    var line = installer.execute("grep", new Array(key + "=", installer.value("systemConfigFilePath")))[0];
    if (line) {
        var parts = line.split("=");
        if (parts.length > 1) {
            return (parts[1]).replace(/\r?\n|\r/g, "");
        }
    }
    return undefined;
}

function log(msg) {
    console.log(msg);
    installer.execute("/bin/sh", new Array("-c", "echo '" + msg + "' >> " + installer.value("logPath") + "/" + installer.value("logFile")));
}
