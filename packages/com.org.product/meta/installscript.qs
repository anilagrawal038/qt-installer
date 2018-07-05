var systemConfigFilePath;
var versionKey;
var releaseKey;
var osKey;
var installationPathKey;
var dataExtracted = false;

function Component() {
    // constructor
    log("Inside QT Demo Component()");
    systemConfigFilePath = installer.value("systemConfigFilePath");
    versionKey = installer.value("versionKey");
    releaseKey = installer.value("releaseKey");
    osKey = installer.value("osKey");
    installationPathKey = installer.value("installationPathKey");
    component.loaded.connect(this, Component.prototype.loaded);
    validateOptions();
    if (installer.value("_nonRootUser") == "true" || installer.value("_installationFound") == 'true') {
        log("Going to launch AbortInstallationPage");
        installer.addWizardPage(component, "AbortInstallationPage", QInstaller.TargetDirectory);
        log("AbortInstallationPage added");
    }

    installer.installationFinished.connect(onInstallationCompletion);
    installer.uninstallationFinished.connect(onUninstallationCompletion);
}

Component.prototype.loaded = function () {
    log("Inside QT Demo Component.prototype.loaded()");
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

Component.prototype.dynamicInstallationDetailsPageEntered = function () {
    log("Inside QT Demo Component.prototype.dynamicInstallationDetailsPageEntered()");
    // var pageWidget = gui.pageWidgetByObjectName("DynamicInstallationDetailsPage");
}

Component.prototype.createOperations = function () {
    log("Inside QT Demo Component.prototype.createOperations()");
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
        log("Inside QT Demo Component (Installer mode : Upgrade)");
        upgradeQTDemo();
    } else {
        log("Inside QT Demo Component (Installer mode : Install)");
    }
}


function onInstallationCompletion() {
    log("Inside onInstallationCompletion(com.org.product)");
}

function onUninstallationCompletion() {
    log("Inside onUninstallationCompletion(com.org.product)");
}

function upgradeQTDemo() {
    log("Inside upgradeQTDemo()");
    var targetDir = installer.value("TargetDir");
    var installationPath = installer.value("existingInstallationPath");

    // component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Module4/webapp");
    // component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Module4/lib/module4.war");
    // component.addElevatedOperation("Execute", "{0,1,2,3,4,5,15}", "cp", installationPath + "InstallationLog.txt", installationPath + "InstallationLog_old.txt");

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

function validateOptions() {
    if (installer.value("_installationFound") != 'true' && (installer.value('uninstall') == 'true' || installer.value('upgrade') == 'true')) {
        if (installer.value("silent") == 'true') {
            log("No existing QT Demo installation found but option (Upgrade/Uninstall) provided in silent mode. Interrupting installation.");
            gui.cancelButtonClicked();
            return false;
        } else {
            if (QMessageBox.critical("installer-critical", "Installer", 'No existing QT Demo  installation found but Upgrade/Uninstall option provided through command line options. Interrupting installation.', QMessageBox.Ok) == QMessageBox.Ok) {
                gui.cancelButtonClicked();
                return false;
            }
        }
    } else {
        return true;
    }
}

function log(msg) {
    console.log(msg);
    installer.execute("/bin/sh", new Array("-c", "echo '" + msg + "' >> " + installer.value("logPath") + "/" + installer.value("logFile")));
}

