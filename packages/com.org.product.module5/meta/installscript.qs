var dataExtracted = false;

function Component() {
    // constructor
    log("Inside Module5 Component()");
    component.loaded.connect(this, Component.prototype.loaded);
}

Component.prototype.loaded = function () {
    log("Inside Module5 Component.prototype.loaded()");
}

Component.prototype.isDefault = function () {
    if (installer.value("installerInUpgradationMode") == "true" || installer.fileExists(installer.value("systemConfigFilePath"))) {
        if (getConfProperty("com.org.product.module5") == "true") {
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

Component.prototype.dynamicModule5ConfigurationPageEntered = function () {
    log("Inside Module5 Component.prototype.dynamicModule5ConfigurationPageEntered()");
    // var pageWidget = gui.pageWidgetByObjectName("DynamicModule5ConfigurationPage");
}

Component.prototype.createOperations = function () {
    log("Inside Module5 Component.prototype.createOperations()");
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
        log("Inside Module5 Component (Installer mode : Upgrade)");
        upgradeModule5();
    } else {
        log("Inside Module5 Component (Installer mode : Install)");
        installModule5();
        uninstallModule5();
    }

}

function installModule5() {
    log("Inside QT Demo installModule5()");
    var destDir = installer.value("TargetDir") + "/Module5";

    // component.addElevatedOperation("Execute", "ln", new Array("-s", destDir + "/lib/libwrap.so.1.0", destDir + "/lib/libwrap.so"), "UNDOEXECUTE", "unlink", "libwrap.so", "workingdirectory=" + destDir + "/lib");
    // component.addElevatedOperation("Execute", "ldconfig");

    // component.addElevatedOperation("Execute", "sed", "-i", "--", "s|<Module5-Path>|" + destDir + "|", destDir + "/conf/Module5Service");

    // component.addElevatedOperation("Copy", destDir + "/conf/Module5Service", "/etc/init.d/");
    // component.addElevatedOperation("Execute", "chmod", "+x", "/etc/init.d/Module5Service");
}

function uninstallModule5() {
    log("Register opeartions for uninstallModule5()");
    var destDir = installer.value("TargetDir") + "/Module5";

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "service", "Module5Service", "stop");
    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", "service Module5Service status && kill -s TERM  $(ps -ax | grep Module5Service | head -1 | awk -F' ' '{print $1}')");

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "rm", "-f", "/etc/init.d/Module5Service");
    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "rm", "-f", "/etc/ld.so.conf.d/libs.conf");

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "chkconfig", new Array("--del", "Module5Service"));
}

function upgradeModule5() {
    log("Inside upgradeModule5()");
    var targetDir = installer.value("TargetDir");
    /*
    component.addElevatedOperation("Execute", "{0,1,2,3,4,5,15}", "service", "Module5Service", "stop");
    component.addElevatedOperation("Execute", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", "service Module5Service status && kill -s TERM  $(ps -ax | grep Module5Service | head -1 | awk -F' ' '{print $1}')");

    var installationPath = installer.value("existingInstallationPath");

    if (installer.fileExists(installationPath + "/Module5/lib/libwrap.so")) {
        // , "{0,1,2,3,4,5,15,255}"
        component.addElevatedOperation("Execute", "unlink", "libwrap.so", "workingdirectory=" + installationPath + "/Module5/lib");
    }

    component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Module5/lib");
    component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Module5/bin");
    component.addElevatedOperation("Execute", "cp", "-Rf", targetDir + "/Module5/lib", installationPath + "/Module5");
    component.addElevatedOperation("Execute", "cp", "-Rf", targetDir + "/Module5/bin", installationPath + "/Module5");
    component.addElevatedOperation("Execute", "ln", new Array("-s", installationPath + "/Module5/lib/libwrap.so.1.0", installationPath + "/Module5/lib/libwrap.so"));
    component.addElevatedOperation("Execute", "ldconfig", "workingdirectory=" + installationPath);
    */
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

