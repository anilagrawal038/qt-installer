var dataExtracted = false;
var _showInfoDialogClosed;

function Component() {
    // constructor
    log("Inside QT Demo Module1 Component()");
    component.loaded.connect(this, Component.prototype.loaded);
}

Component.prototype.loaded = function () {
    log("Inside QT Demo Module1 Component.prototype.loaded()");
}

Component.prototype.isDefault = function () {
    log("Inside Component.prototype.isDefault()");
    log("installerInUpgradationMode : " + installer.value("installerInUpgradationMode"));
    if (installer.value("installerInUpgradationMode") == "true" || installer.fileExists(installer.value("systemConfigFilePath"))) {
        if (getConfProperty("com.org.product.module1") == "true") {
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

Component.prototype.dynamicModule1ConfigurationPageEntered = function () {
    log("Inside QT Demo Module1 Component.prototype.dynamicModule1ConfigurationPageEntered()");
    // var pageWidget = gui.pageWidgetByObjectName("DynamicModule1ConfigurationPage");
}

Component.prototype.createOperations = function () {
    log("Inside QT Demo Module1 Component.prototype.createOperations()");
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
        log("Inside QT Demo Module1 Component (Installer mode : Upgrade)");
    } else {
        log("Inside QT Demo Module1 Component (Installer mode : Install)");
        installModule1();
        uninstallModule1();
    }

}

function installModule1() {
    log("Inside installModule1()");
    var homeDir = installer.value("HomeDir");

    var destDir = installer.value("TargetDir") + "/Module1";
    // var module1Port = installer.value("module1Port") + "";
    // if (module1Port != "1234") {
        // log("Changing Module1 port to : " + module1Port);
        // component.addElevatedOperation("Execute", "sed", "-i", "s/native_transport_port:.*/native_transport_port: " + module1Port + "/", destDir + "/conf/module1.yaml");
    // }

    /*
    var scriptDir;
    if (installer.fileExists("/etc/init.d")) {
        // # System V style
        scriptDir = "/etc/init.d";
    } else if (installer.fileExists("/etc/rc.d")) {
        // # BSD style
        scriptDir = "/etc/rc.d";
    } else {
        log("Unsupported init script system. Aborting installation");
        installer.setValue("_interruptReason", "Unsupported init script system");
        installer.interrupt();
        return;
    }

    component.addElevatedOperation("Copy", destDir + "/bin/Module1Service", scriptDir);
    component.addElevatedOperation("Execute", "sed", new Array("-i", "/export Module1_HOME=/d", homeDir + "/.bashrc"));
    component.addElevatedOperation("Execute", "/bin/sh", new Array("-c", "echo  'export Module1_HOME=" + destDir + "' >> " + homeDir + "/.bashrc"));
    // component.addElevatedOperation("Execute", "source", homeDir + "/.bashrc");
    */
}

function uninstallModule1() {
    log("Register opeartions for uninstallModule1()");
    var destDir = installer.value("TargetDir") + "/Module1";
    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "service", "Module1Service", "stop");
    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", "service Module1Service status && kill -s TERM  $(ps -ax | grep Module1Service | head -1 | awk -F' ' '{print $1}')");

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "rm", "-f", "/etc/init.d/Module1Service");

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "sed", new Array("-i", "/export Module1_HOME=/d", installer.value("HomeDir") + "/.bashrc"));
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

