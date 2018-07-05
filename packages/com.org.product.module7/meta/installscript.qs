var dataExtracted = false;

function Component() {
    // constructor
    log("Inside Module7 Component()");
    component.loaded.connect(this, Component.prototype.loaded);
}

Component.prototype.loaded = function () {
    log("Inside Module7 Component.prototype.loaded()");
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

Component.prototype.dynamicModule7ConfigurationPageEntered = function () {
    log("Inside Module7 Component.prototype.dynamicModule7ConfigurationPageEntered()");
    // var pageWidget = gui.pageWidgetByObjectName("DynamicModule7ConfigurationPage");
}

Component.prototype.createOperations = function () {
    log("Inside Module7 Component.prototype.createOperations()");
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
        log("Inside Module7 Component (Installer mode : Upgrade)");
        upgrademodule7();
    } else {
        log("Inside Module7 Component (Installer mode : Install)");
        installmodule7();
        uninstallModule7();
    }

}

function installmodule7() {
    log("Inside QT Demo installmodule7()");
    var targetDir = installer.value("TargetDir");
    /*
    component.addElevatedOperation("Execute", "/bin/sh", "-c", "chmod +x " + targetDir + "/Module7/yajsw-stable-11.11/bin/*.sh");

    if (installer.fileExists(targetDir + "/Module7/webapp")) {
        log("Removing existing webapp folder");
        component.addElevatedOperation("Execute", "rm", "-Rf", targetDir + "/Module7/webapp");
    }

    log("Extracting Module7 webapp");
    component.addElevatedOperation("Execute", "unzip", targetDir + "/Module7/lib/module7.war", "-d", targetDir + "/Module7/webapp");

    log("Configuring Module7");
    var installModule4 = 1;
    var installModule5 = 1;
    var installModule1 = 1;
    if (installer.value("installationRequested_com.org.product.module4") == "false") {
        installModule4 = 0;
    }
    if (installer.value("installationRequested_com.org.product.module5") == "false") {
        installModule5 = 0;
    }
    if (installer.value("installationRequested_com.org.product.module1") == "false") {
        installModule1 = 0;
    }

    log("Execute java -jar " + targetDir + "/Module7/lib/Config.jar install " + targetDir + "/Module7 " + installModule4 + " " + installModule5 + " " + installModule1 + " " + installer.value("module7Port") + " " + installer.value("module4Port") + " " + installer.value("module5Port") + " " + installer.value("module1Port") + " None");

    component.addElevatedOperation("Execute", "java", new Array("-jar", targetDir + "/Module7/lib/Config.jar", "install", targetDir + "/Module7", installModule4, installModule5, installModule1, installer.value("module7Port"), installer.value("module4Port"), installer.value("module5Port"), installer.value("module1Port"), "None"));
    */
}

function uninstallModule7() {
    log("Register opeartions for uninstallModule7()");
    var destDir = installer.value("TargetDir") + "/Module7";
    /*
    component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "service", "Module7Service", "stop");
    component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", "service Module7Service status && kill -s TERM  $(ps -ax | grep Module7Service | head -1 | awk -F' ' '{print $1}')");

    component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "/bin/sh", destDir + "/yajsw-stable-11.11/bin/uninstallDaemon.sh");

    component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "chkconfig", "--del", "Module7Service");
    component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "xdg-desktop-menu", "uninstall", "module7.desktop");
    */
}

function upgrademodule7() {
    log("Inside upgrademodule7()");
    /*
    var targetDir = installer.value("TargetDir");
    component.addElevatedOperation("Execute", "{0,1,2,3,4,5,15}", "service", "Module7Service", "stop");
    component.addElevatedOperation("Execute", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", "service Module7Service status && kill -s TERM  $(ps -ax | grep Module7Service | head -1 | awk -F' ' '{print $1}')");

    var installationPath = installer.value("existingInstallationPath");
    component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Module7/webapp");
    component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Module7/lib/module7.war");
    component.addElevatedOperation("Copy", targetDir + "/Module7/lib/module7.war", installationPath + "/Module7/lib/module7.war");
    component.addElevatedOperation("Execute", "unzip", installationPath + "/Module7/lib/module7.war", "-d", installationPath + "/Module7/webapp");
    */
}

function log(msg) {
    console.log(msg);
    installer.execute("/bin/sh", new Array("-c", "echo '" + msg + "' >> " + installer.value("logPath") + "/" + installer.value("logFile")));
}

