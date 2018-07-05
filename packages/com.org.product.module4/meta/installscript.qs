var dataExtracted = false;

function Component() {
    // constructor
    log("Inside Module4 Component()");
    component.loaded.connect(this, Component.prototype.loaded);
}

Component.prototype.loaded = function () {
    log("Inside Module4 Component.prototype.loaded()");
}

Component.prototype.isDefault = function () {
    if (installer.value("installerInUpgradationMode") == "true" || installer.fileExists(installer.value("systemConfigFilePath"))) {
        if (getConfProperty("com.org.product.module4") == "true") {
            return true;
        } else {
            return false;
        }
    } else {
        return true;
    }
}

Component.prototype.createOperationsForArchive = function (archive) {
    log("Inside Component.prototype.createOperationsForArchive()");
    try {
        component.createOperationsForArchive(archive);
        dataExtracted = true;
    } catch (e) {
        log(e);
    }
}

Component.prototype.createOperationsForPath = function (path) {
    log("Inside Component.prototype.createOperationsForPath()");
    try {
        component.createOperationsForPath(path);
    } catch (e) {
        log(e);
    }
}

Component.prototype.dynamicModule4ConfigurationPageEntered = function () {
    log("Inside Module4 Component.prototype.dynamicModule4ConfigurationPageEntered()");
    // var pageWidget = gui.pageWidgetByObjectName("DynamicModule4ConfigurationPage");
}

Component.prototype.createOperations = function () {
    log("Inside Module4 Component.prototype.createOperations()");
    try {
        component.createOperations();
    } catch (e) {
        log(e);
    }
    if (!dataExtracted) {
        log("Data Extraction status : " + dataExtracted);
        component.createOperationsForArchive(component.archives[0]);
    }

    if (installer.value("installerInUpgradationMode") == "true") {
        log("Inside Module4 Component (Installer mode : Upgrade)");
        upgradeModule4();
    } else {
        log("Inside Module4 Component (Installer mode : Install)");
        installModule4();
        uninstallModule4();
    }

}

function installModule4() {
    log("Inside QT Demo installModule4()");
    var targetDir = installer.value("TargetDir");
    /*
    component.addElevatedOperation("Execute", "/bin/sh", "-c", "chmod +x " + targetDir + "/Module4/service/yajsw-stable-11.11/bin/*.sh");

    if (installer.fileExists(targetDir + "/Module4/webapp")) {
        log("Removing existing webapp folder");
        component.addElevatedOperation("Execute", "rm", "-Rf", targetDir + "/Module4/webapp");
    }

    log("Extracting Module4 webapp");
    component.addElevatedOperation("Execute", "unzip", targetDir + "/Module4/lib/module4.war", "-d", targetDir + "/Module4/webapp");
    */
}

function uninstallModule4() {
    log("Register opeartions for uninstallModule4()");
    var destDir = installer.value("TargetDir") + "/Module4";
    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "service", "Module4Service", "stop");
    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", "service Module4Service status && kill -s TERM  $(ps -ax | grep Module4Service | head -1 | awk -F' ' '{print $1}')");

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "/bin/sh", destDir + "/service/yajsw-stable-11.11/bin/uninstallDaemon.sh");

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "chkconfig", "--del", "Module4Service");
    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "xdg-desktop-menu", "uninstall", "module4.desktop");
    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "xdg-desktop-menu", "uninstall", "module4-user-guide.desktop");
}

function upgradeModule4() {
    log("Inside upgradeModule4()");
    var targetDir = installer.value("TargetDir");

    // component.addElevatedOperation("Execute", "{0,1,2,3,4,5,15}", "service", "Module4Service", "stop");
    // component.addElevatedOperation("Execute", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", "service Module4Service status && kill -s TERM  $(ps -ax | grep Module4Service | head -1 | awk -F' ' '{print $1}')");

    // var installationPath = installer.value("existingInstallationPath");
    // component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Module4/webapp");
    // component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Module4/lib/module4.war");
    // component.addElevatedOperation("Copy", targetDir + "/Module4/lib/module4.war", installationPath + "/Module4/lib/module4.war");
    // component.addElevatedOperation("Execute", "unzip", installationPath + "/Module4/lib/module4.war", "-d", installationPath + "/Module4/webapp");

}

function getConfProperty(key) {
    var line = installer.execute("grep", new Array(key, installer.value("systemConfigFilePath")))[0];
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

