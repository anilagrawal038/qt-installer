var dataExtracted = false;

function Component() {
    // constructor
    log("Inside Test Product Service Manager Component()");
    component.loaded.connect(this, Component.prototype.loaded);
}

Component.prototype.loaded = function () {
    log("Inside Test Product Service Manager Component.prototype.loaded()");
}

Component.prototype.dynamicServiceManagerConfigurationPageEntered = function () {
    log("Inside Test Product Service Manager Component.prototype.dynamicServiceManagerConfigurationPageEntered()");
    // var pageWidget = gui.pageWidgetByObjectName("DynamicServiceManagerConfigurationPage");
}

Component.prototype.createOperations = function () {
    log("Inside Test Product Service Manager Component.prototype.createOperations()");
    try {
        component.createOperations();
    } catch (e) {
        log(e);
    }
    if (installer.value("installerInUpgradationMode") == "true") {
        log("Inside Test Product Service Manager Component (Installer mode : Upgrade)");
        upgradeServiceManager();
    } else {
        log("Inside Test Product Service Manager Component (Installer mode : Install)");
        installServiceManager();
        uninstallServiceManager();
    }

}

function installServiceManager() {
    log("Inside Test Product installServiceManager()");
    var targetDir = installer.value("TargetDir");
}

function uninstallServiceManager() {
    log("Register opeartions for uninstallServiceManager()");
    var destDir = installer.value("TargetDir") + "/ServiceManager";
}

function upgradeServiceManager() {
    log("Inside upgradeServiceManager()");
    var targetDir = installer.value("TargetDir");
}

function log(msg) {
    console.log(msg);
    installer.execute("/bin/sh", new Array("-c", "echo '" + msg + "' >> " + installer.value("logPath") + "/" + installer.value("logFile")));
}
