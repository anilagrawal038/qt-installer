var dataExtracted = false;

function Component() {
    // constructor
    log("Inside QT Demo Module2 Component()");
    component.loaded.connect(this, Component.prototype.loaded);
}

Component.prototype.loaded = function () {
    log("Inside QT Demo Module2 Component.prototype.loaded()");
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
    log("Inside QT Demo Module2 Component.prototype.createOperations()");
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
        log("Inside QT Demo Module2 Component (Installer mode : Upgrade)");
    } else {
        log("Inside QT Demo Module2 Component (Installer mode : Install)");
        installModule2Service();
        uninstallModule2();
    }

}

function installModule2Service() {
    log("Inside QT Demo installModule2Service()");
    var destDir = installer.value("TargetDir") + "/Module2";
    var homeDir = installer.value("HomeDir");

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

    /*
    var Module2ServiceOptions = "";

    if (installer.value("installationRequested_com.org.product.module5") == "true") {
        Module2ServiceOptions += " true true";
    } else {
        Module2ServiceOptions += " false false";
    }

    if (installer.value("installationRequested_com.org.product.module1") == "true") {
        Module2ServiceOptions += " true";
    } else {
        Module2ServiceOptions += " false";
    }

    component.addElevatedOperation("Execute", "sed", "-i", "s/<Module2Service-Options>/" + Module2ServiceOptions + "/", destDir + "/Module2Service");

    component.addElevatedOperation("Copy", destDir + "/Module2Service", scriptDir);
    component.addElevatedOperation("Execute", "chmod", "+x", "/etc/init.d/Module2Service");

    component.addElevatedOperation("Execute", "sed", new Array("-i", "/export Module2_HOME=/d", homeDir + "/.bashrc"));
    component.addElevatedOperation("Execute", "/bin/sh", "-c", "echo 'export Module2_HOME=" + destDir + "' >> " + homeDir + "/.bashrc");
    // component.addElevatedOperation("Execute", "source", homeDir + "/.bashrc");

    component.addElevatedOperation("Execute", "chkconfig", "--add", "Module2Service");
    */
}

function uninstallModule2() {
    log("Register opeartions for uninstallModule2()");
    var destDir = installer.value("TargetDir") + "/Module2";
    var homeDir = installer.value("HomeDir");

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "service", "Module2Service", "stop");
    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", "service Module2Service status && kill -s TERM  $(ps -ax | grep Module2Service | head -1 | awk -F' ' '{print $1}')");


    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "rm", "-f", "/etc/init.d/Module2Service");
    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "sed", new Array("-i", "/Module2_HOME/d", homeDir + "/.bashrc"));

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "chkconfig", new Array("--del", "Module2Service"));
}

function log(msg) {
    console.log(msg);
    installer.execute("/bin/sh", new Array("-c", "echo '" + msg + "' >> " + installer.value("logPath") + "/" + installer.value("logFile")));
}


