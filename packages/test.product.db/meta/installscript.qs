var dataExtracted = false;
var _showInfoDialogClosed;

function Component() {
    // constructor
    log("Inside Test Product DB Component()");
    component.loaded.connect(this, Component.prototype.loaded);
}

Component.prototype.loaded = function () {
    log("Inside Test Product DB Component.prototype.loaded()");
}

Component.prototype.isDefault = function () {
    log("Inside Test Product DB Component.prototype.isDefault()");
    log("Inside Test Product DB  isDefault() systemConfigFilePath : " + installer.value("systemConfigFilePath"));
    log("Inside Test Product DB  isDefault() installerInUpgradationMode : " + installer.value("installerInUpgradationMode"));
    if (installer.value("installerInUpgradationMode") == "true" || installer.fileExists(installer.value("systemConfigFilePath"))) {
        if (getConfProperty("test.product.db") == "true") {
            return true;
        } else {
            return false;
        }
    } else {
        return true;
    }
}

Component.prototype.dynamicDBConfigurationPageEntered = function () {
    log("Inside Test Product DB Component.prototype.dynamicDBConfigurationPageEntered()");
    // var pageWidget = gui.pageWidgetByObjectName("DynamicDBConfigurationPage");
}

Component.prototype.createOperations = function () {
    log("Inside Test Product DB Component.prototype.createOperations()");
    try {
        component.createOperations();
    } catch (e) {
        log(e);
    }

    if (installer.value("installerInUpgradationMode") == "true") {
        log("Inside Test Product DB Component (Installer mode : Upgrade)");
    } else {
        log("Inside Test Product DB Component (Installer mode : Install)");
        installDB();
        uninstallDB();
    }

}

function installDB() {
    log("Inside installDB()");
    var homeDir = installer.value("HomeDir");

    var destDir = installer.value("TargetDir") + "/DB";
    var dbPort = installer.value("dbPort") + "";
}

function uninstallDB() {
    log("Register opeartions for uninstallDB()");
    var destDir = installer.value("TargetDir") + "/DB";
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
