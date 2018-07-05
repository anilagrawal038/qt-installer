var systemConfigFilePath;
var versionKey;
var buildKey;
var osKey;
var installationPathKey;
var dataExtracted = false;

function Component() {
    // constructor
    log("Inside QT Demo Module Component()");
    systemConfigFilePath = installer.value("systemConfigFilePath");
    versionKey = installer.value("versionKey");
    buildKey = installer.value("buildKey");
    osKey = installer.value("osKey");
    installationPathKey = installer.value("installationPathKey");
    component.loaded.connect(this, Component.prototype.loaded);
}

Component.prototype.loaded = function () {
    log("Inside QT Demo Module Component.prototype.loaded()");
}

Component.prototype.createOperationsForArchive = function (archive) {
    log("Inside Module Component.prototype.createOperationsForArchive()");
    try {
        component.createOperationsForArchive(archive);
        dataExtracted = true;
    } catch (e) {
        log(e);
    }
}

Component.prototype.createOperationsForPath = function (path) {
    log("Inside Module Component.prototype.createOperationsForPath()");
    try {
        component.createOperationsForPath(path);
    } catch (e) {
        log(e);
    }
}

Component.prototype.createOperations = function () {
    log("Inside QT Demo Module Component.prototype.createOperations()");
    try {
        component.createOperations();
    } catch (e) {
        log(e);
    }
    if (!dataExtracted) {
        log("Data Extraction status : " + dataExtracted);
        component.createOperationsForArchive(component.archives[0]);
    }

    installer.execute("sed", new Array("-i", "/" + versionKey + "/d", systemConfigFilePath));
    installer.execute("/bin/sh", new Array("-c", "echo " + versionKey + "=" + installer.value("ProductInstallerVersion") + " >> " + systemConfigFilePath));

    installer.execute("sed", new Array("-i", "/" + buildKey + "/d", systemConfigFilePath));
    installer.execute("/bin/sh", new Array("-c", "echo " + buildKey + "=" + installer.value("QTDemoInstallerBuild") + " >> " + systemConfigFilePath));

    if (installer.value("installerInUpgradationMode") == "true") {
        log("Inside QT Demo Module Component (Installer mode : Upgrade)");
    } else {
        log("Inside QT Demo Module Component (Installer mode : Install)");

        installer.execute("sed", new Array("-i", "/" + osKey + "/d", systemConfigFilePath));
        installer.execute("/bin/sh", new Array("-c", "echo " + osKey + "=" + systemInfo.prettyProductName + " >> " + systemConfigFilePath));

        installer.execute("sed", new Array("-i", "/" + installationPathKey + "/d", systemConfigFilePath));
        installer.execute("/bin/sh", new Array("-c", "echo " + installationPathKey + "=" + installer.value("TargetDir") + " >> " + systemConfigFilePath));

        installer.execute("sed", new Array("-i", "/com.org.product/d", systemConfigFilePath));
        var components = installer.components();
        for (i = 0; i < components.length; i++) {
            installer.execute("/bin/sh", new Array("-c", "echo " + components[i].name + "=" + components[i].installationRequested() + " >> " + systemConfigFilePath));
        }
        installDesktopItemsForQTDemo();
        uninstallQTDemo();
    }

}

function installDesktopItemsForQTDemo() {
    log("Inside Module installDesktopItemsForQTDemo()");
    var destDir = installer.value("TargetDir") + "/Module";

    /*
    component.addElevatedOperation("Execute", "sed", new Array("-i", "--", "s|<INSTALL-Path>|" + destDir + "/bin/launchModule7.sh|", destDir + "/bin/Module7.desktop"));
    component.addElevatedOperation("Execute", "sed", new Array("-i", "--", "s|<Icon-Path>|" + destDir + "/bin/icons/favicon.ico|", destDir + "/bin/Module7.desktop"));
    component.addElevatedOperation("Execute", "chmod", new Array("+x", destDir + "/bin/launchModule7.sh"));

    component.addElevatedOperation("Execute", "sed", new Array("-i", "--", "s|<INSTALL-Path>|" + destDir + "/bin/launchModule4Service.sh|", destDir + "/bin/module4.desktop"));
    component.addElevatedOperation("Execute", "sed", new Array("-i", "--", "s|<Icon-Path>|" + destDir + "/bin/icons/favicon.ico|", destDir + "/bin/module4.desktop"));
    component.addElevatedOperation("Execute", "chmod", new Array("+x", destDir + "/bin/launchModule4Service.sh"));

    component.addElevatedOperation("Execute", "sed", new Array("-i", "--", "s|<INSTALL-Path>|" + destDir + "/bin/launchModule4UserGuide.sh|", destDir + "/bin/module4-user-guide.desktop"));
    component.addElevatedOperation("Execute", "sed", new Array("-i", "--", "s|<Icon-Path>|" + destDir + "/bin/icons/pdf.ico|", destDir + "/bin/module4-user-guide.desktop"));
    component.addElevatedOperation("Execute", "chmod", new Array("+x", destDir + "/bin/launchModule4UserGuide.sh"));

    if (installer.value("installationRequested_com.org.product.module7") == "true") {
        component.addElevatedOperation("Execute", "xdg-desktop-menu", new Array("install", destDir + "/bin/Module7.desktop"));
    }
    if (installer.value("installationRequested_com.org.product.module4") == "true") {
        component.addElevatedOperation("Execute", "xdg-desktop-menu", new Array("install", destDir + "/bin/module4.desktop"));
        component.addElevatedOperation("Execute", "xdg-desktop-menu", new Array("install", destDir + "/bin/module4-user-guide.desktop"));
    }
    if (installer.value("installationRequested_com.org.product.module5") == "true") {
    }
    if (installer.value("installationRequested_com.org.product.module1") == "true") {
    }
    */
}

function uninstallQTDemo() {
    log("Inside Module Register opeartions for uninstallQTDemo()");
    var homeDir = installer.value("HomeDir");

    component.addOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "rm", "-f", installer.value("systemConfigFilePath"));

    // component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "sed", new Array("-i", "/launchQTDemoOnFirstRun/d", homeDir + "/.bashrc"));
}

function log(msg) {
    console.log(msg);
    installer.execute("/bin/sh", new Array("-c", "echo '" + msg + "' >> " + installer.value("logPath") + "/" + installer.value("logFile")));
}
