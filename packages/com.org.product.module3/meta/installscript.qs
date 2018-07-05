var dataExtracted = false;

function Component() {
    // constructor
    log("Inside QT Demo Module3 Component()");
    component.loaded.connect(this, Component.prototype.loaded);
}

Component.prototype.loaded = function () {
    log("Inside QT Demo Module3 Component.prototype.loaded()");
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

Component.prototype.createOperations = function () {
    log("Inside QT Demo Module3 Component.prototype.createOperations()");
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
        log("Inside QT Demo Module3 Component (Installer mode : Upgrade)");
    } else {
        log("Inside QT Demo Module3 Component (Installer mode : Install)");
        installModule3();
        uninstallModule3();
    }

}

function installModule3() {
    log("Inside installModule3()");
    var destDir = installer.value("TargetDir") + "/Module3";

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

    if (installer.fileExists(scriptDir + "/Module1Service1")) {
        component.addElevatedOperation("Delete", scriptDir + "/Module1Service1");
    }

    if (installer.fileExists(scriptDir + "/Module1Service2")) {
        component.addElevatedOperation("Delete", scriptDir + "/Module1Service2");
    }

    component.addElevatedOperation("Copy", destDir + "/scripts/Module1Service1", scriptDir);
    component.addElevatedOperation("Copy", destDir + "/scripts/Module1Service2", scriptDir);

    var tmp = "s|<Module3_HOME>|" + destDir + "|";
    component.addElevatedOperation("Execute", "sed", new Array("-i", "--", tmp, destDir + "/config/Module1Service1.properties"));
    component.addElevatedOperation("Execute", "sed", new Array("-i", "--", tmp, destDir + "/config/server.properties"));

    var file = installer.value("HomeDir") + "/.bashrc";
    component.addElevatedOperation("Execute", "sed", new Array("-i", "/export Module3_HOME=/d", file));
    component.addElevatedOperation("Execute", "/bin/sh", new Array("-c", "echo 'export Module3_HOME=" + destDir + "' >> " + file));
    */
}

function uninstallModule3() {
    log("Register opeartions for uninstallModule3()");
    var destDir = installer.value("TargetDir") + "/Module3";

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "service", "Module1Service2", "stop");
    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", "service Module1Service2 status && kill -s TERM  $(ps -ax | grep Module1Service2 | head -1 | awk -F' ' '{print $1}')");

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "service", "Module1Service1", "stop");
    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", "service Module1Service1 status && kill -s TERM  $(ps -ax | grep Module1Service1 | head -1 | awk -F' ' '{print $1}')");

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "rm", "-f", "/etc/init.d/Module1Service2");
    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "rm", "-f", "/etc/init.d/Module1Service1");

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "sed", new Array("-i", "/export Module3_HOME=/d", installer.value("HomeDir") + "/.bashrc"));
}

function log(msg) {
    console.log(msg);
    installer.execute("/bin/sh", new Array("-c", "echo '" + msg + "' >> " + installer.value("logPath") + "/" + installer.value("logFile")));
}


