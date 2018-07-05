var dataExtracted = false;

function Component() {
    // constructor
    log("Inside QT Demo Module6 Component()");
    component.loaded.connect(this, Component.prototype.loaded);
}

Component.prototype.loaded = function () {
    log("Inside QT Demo Module6 Component.prototype.loaded()");
}

Component.prototype.createOperationsForArchive = function (archive) {
    log("Inside QT Demo Module6 Component.prototype.createOperationsForArchive()");
    try {
        component.createOperationsForArchive(archive);
        dataExtracted = true;
    } catch (e) {
        log(e);
    }
}

Component.prototype.createOperationsForPath = function (path) {
    log("Inside QT Demo Module6 Component.prototype.createOperationsForPath()");
    try {
        component.createOperationsForPath(path);
    } catch (e) {
        log(e);
    }
}

Component.prototype.createOperations = function () {
    log("Inside QT Demo Module6 Component.prototype.createOperations()");
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
        log("Inside QT Demo Module6 Component (Installer mode : Upgrade)");
        upgradeModule6();
    } else {
        log("Inside QT Demo Module6 Component (Installer mode : Install)");
        installModule6();
        uninstallModule6();
    }

}

function installModule6() {
    log("Inside QT Demo Module6 Component.prototype.installModule6()");
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
    scriptDir = installer.value("TargetDir") + "/Module6";
    // component.addElevatedOperation("Execute", "/bin/sh", scriptDir + "/install.sh", "workingdirectory=" + scriptDir);

}

function uninstallModule6() {
    log("Register opeartions for uninstallModule6()");
    var destDir = installer.value("TargetDir") + "/Module6";

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "/bin/sh", destDir + "/scripts/stop_app.sh");

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", "service Module6Service status && kill -s TERM  $(ps -ax | grep Module6Service | head -1 | awk -F' ' '{print $1}')");
}

function upgradeModule6() {
    log("Inside upgradeModule6()");
    var targetDir = installer.value("TargetDir");

    /*
    component.addElevatedOperation("Execute", "{0,1,2,3,4,5,15}", "/bin/sh", targetDir + "/scripts/stop_app.sh");
    component.addElevatedOperation("Execute", "{0,1,2,3,4,5,15}", "service", "Module6Service", "stop");
    component.addElevatedOperation("Execute", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", "service Module6Service status && kill -s TERM  $(ps -ax | grep Module6Service | head -1 | awk -F' ' '{print $1}')");

    var installationPath = installer.value("existingInstallationPath");

    component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Module6/module6.tar");
    component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Module6/version.txt");
    component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Module6/Release_Notes.docx");
    component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Module6/install_1.sh");
    component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Module6/install.sh");


    component.addElevatedOperation("Copy", targetDir + "/Module6/module6.tar", installationPath + "/Module6/module6.tar");
    component.addElevatedOperation("Copy", targetDir + "/Module6/version.txt", installationPath + "/Module6/version.txt");
    component.addElevatedOperation("Copy", targetDir + "/Module6/Release_Notes.docx", installationPath + "/Module6/Release_Notes.docx");
    component.addElevatedOperation("Copy", targetDir + "/Module6/install_1.sh", installationPath + "/Module6/install_1.sh");
    component.addElevatedOperation("Copy", targetDir + "/Module6/install.sh", installationPath + "/Module6/install.sh");
    // component.addElevatedOperation("Copy", installationPath + "/Module6/config.cfg", installationPath + "/Module6/_config.cfg_bk");


    component.addElevatedOperation("Execute", "/bin/sh", installationPath + "/Module6/install.sh", "workingdirectory=" + installationPath + "/Module6");

    */
}

function log(msg) {
    console.log(msg);
    installer.execute("/bin/sh", new Array("-c", "echo '" + msg + "' >> " + installer.value("logPath") + "/" + installer.value("logFile")));
}

