var dataExtracted = false;

function Component() {
    // constructor
    log("Inside Test Product Manager Component()");
    component.loaded.connect(this, Component.prototype.loaded);
}

Component.prototype.loaded = function () {
    log("Inside Test Product Manager Component.prototype.loaded()");
}

Component.prototype.isDefault = function () {
    log("Inside Test Product Manager  isDefault() systemConfigFilePath : " + installer.value("systemConfigFilePath"));
    log("Inside Test Product Manager  isDefault() installerInUpgradationMode : " + installer.value("installerInUpgradationMode"));
    if (installer.value("installerInUpgradationMode") == "true" || installer.fileExists(installer.value("systemConfigFilePath"))) {
        if (getConfProperty("test.product.manager") == "true") {
            return true;
        } else {
            return false;
        }
    } else {
        return true;
    }
}

Component.prototype.dynamicManagerConfigurationPageEntered = function () {
    log("Inside Test Product Manager Component.prototype.dynamicManagerConfigurationPageEntered()");
    // var pageWidget = gui.pageWidgetByObjectName("DynamicManagerConfigurationPage");
}

Component.prototype.createOperations = function () {
    log("Inside Test Product Manager Component.prototype.createOperations()");
    try {
        component.createOperations();
    } catch (e) {
        log(e);
    }

    if (installer.value("installerInUpgradationMode") == "true") {
        log("Inside Test Product Manager Component (Installer mode : Upgrade)");
        upgradeManager();
    } else {
        log("Inside Test Product Manager Component (Installer mode : Install)");
        installManager();
        uninstallManager();
    }
}

function installManager() {
    log("Inside Test Product installManager()");
    var targetDir = installer.value("TargetDir");

}

function uninstallManager() {
    log("Register opeartions for uninstallManager()");
    var destDir = installer.value("TargetDir") + "/Manager";
}

function upgradeManager() {
    log("Inside upgradeManager()");
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
