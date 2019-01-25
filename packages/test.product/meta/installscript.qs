var systemConfigFilePath;
var versionKey;
var releaseKey;
var osKey;
var installationPathKey;
var dataExtracted = false;
var installationComplete = false;
var installerRPM = "";
var targetDir = "";

function Component() {
    // constructor
    log("Inside Test Product Component()");
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
    } else {
        log("Going to add DynamicInstallationDetailsPage");
        installer.addWizardPage(component, "DynamicInstallationDetailsPage", QInstaller.TargetDirectory);
        log("DynamicInstallationDetailsPage added");

    }

    installer.installationFinished.connect(onInstallationCompletion);
    installer.uninstallationFinished.connect(onUninstallationCompletion);
}

Component.prototype.loaded = function () {
    log("Inside Test Product Component.prototype.loaded()");
}

Component.prototype.dynamicInstallationDetailsPageEntered = function () {
    log("Inside Test Product Component.prototype.dynamicInstallationDetailsPageEntered()");
    // var pageWidget = gui.pageWidgetByObjectName("DynamicInstallationDetailsPage");
}

Component.prototype.createOperationsForArchive = function (archive) {
    log("Inside Component.prototype.createOperationsForArchive(), archive : " + archive);
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
    log("Inside Test Product Component.prototype.createOperations()");
    try {
        component.createOperations();
    } catch (e) {
        log(e);
    }

    installerRPM = "TestProduct-" + installer.value("InstallerVersion") + "-" + installer.value("InstallerBuild") + ".x86_64.rpm";
    targetDir = installer.value("TargetDir");
    installerRPM = targetDir + "/pkg/" + installerRPM;

    if (installer.value("dbPath") == findInstallationHomeFolder() + "/DB") {
        installer.setValue("dbPath", "");
    }

    if (installer.value("installerInUpgradationMode") == "true") {
        log("Inside Test Product Component (Installer mode : Upgrade)");

        if (execute("ls " + installerRPM)[1] != 0) {
            // component.addOperation("Extract", component.archives[0], "@TargetDir@/tmp");
            installer.performOperation("Extract", new Array(component.archives[0], "@TargetDir@"));
        }

        upgrade();
    } else {
        if (installer.isInstaller()) {

            if (installer.value("portNotAvailable") == "true") {
                if (installer.value("silent") != "true") {
                    QMessageBox.critical("product-installer-critical", "Test Product Installer", "Some of provided ports not available. Aborting Test Product Installation.", QMessageBox.Ok)
                }
                log("Some of provided ports not available. Aborting Test Product Installation.");
                gui.rejectWithoutPrompt();
                return;
            }

            if (execute("ls " + installerRPM)[1] != 0) {
                // component.addOperation("Extract", component.archives[0], "@TargetDir@/tmp");
                installer.performOperation("Extract", new Array(component.archives[0], "@TargetDir@"));
            }
        }
        install();
        log("Inside Test Product Component (Installer mode : Install)");
    }
    uninstall();
}

function populateInstallationDetails() {
    log("Inside populateInstallationDetails()");

    if (getConfProperty("test.product.sm") == "true") {
        log("Test Product Service Manager was installed");
        installer.setValue("smPort", findServicePortFromWrapperConf(findInstallationHomeFolder() + "/ServiceManager/yajsw-stable-11.11/conf/wrapper.conf"));
    } else {
        log("Test Product Service Manager was not installed");
    }
    if (getConfProperty("test.product.monitor") == "true") {
        log("Test Product Monitor was installed");
        installer.setValue("monitorPort", findServicePortFromMonitorConf(findInstallationHomeFolder() + "/Monitor/conf/Monitor.cfg"));
    } else {
        log("Test Product Monitor was not installed");
    }
    if (getConfProperty("test.product.manager") == "true") {
        log("Test Product Manager was installed");
        installer.setValue("managerPort", findServicePortFromWrapperConf(findInstallationHomeFolder() + "/Manager/service/yajsw-stable-11.11/conf/wrapper.conf"));
    } else {
        log("Test Product Manager was not installed");
    }
    if (getConfProperty("test.product.db") == "true") {
        log("Test Product DB was installed");
        installer.setValue("dbPort", getConfProperty("test.product.db.port").trim());
        installer.setValue("dbPath", getConfProperty("test.product.db.path").trim());
    } else {
        log("Test Product DB was not installed");
    }
}

function onInstallationCompletion() {
    log("Inside onInstallationCompletion(test.product)");
    execute("rm -rf " + installer.value("TargetDir") + "/pkg");
    if (!installationComplete) {
        return;
    }
    log("Trying to open TestProduct Service Manager Web page ...");
    if (execute("which xdg-open > /dev/null")[1] == 0) {
        execute("xdg-open http://localhost:" + installer.value("smPort") + " > /dev/null &");
    }
}

function onUninstallationCompletion() {
    log("Inside onUninstallationCompletion(test.product)");
}

function upgrade() {
    log("Inside upgrade()");

    log("Starting TestProduct upgradation wizard ....");
    if (execute("ls " + installerRPM)[1] == 0) {
        if (verifyRPMPackage()) {
            log(installerRPM + " version and release matched with Version:" + installer.value("InstallerVersion") + " Release:" + installer.value("InstallerBuild") + " successfully.");
            populateInstallationDetails();
            var command = populateEnvironmentData();
            command += " rpm -Uvh --prefix  " + findInstallationPath() + " --nofiledigest " + installerRPM + " --nodeps";
            command += " | tee -a " + findLogFile();
            log("Upgrading Test Product");
            log(command);
            component.addElevatedOperation("Execute", "/bin/sh", "-c", command);
            log("Completed TestProduct Upgradation ...");
            installationComplete = true;
        }
    } else {
        log("Could not find " + installerRPM + ". It should be present in the CWD.");
        log("Aborting Test Product Upgradation.");
        if (installer.value("silent") != "true") {
            QMessageBox.critical("product-installer-critical", "Test Product Installer", "Required dependencies not found on path. Aborting Test Product Upgradation.", QMessageBox.Ok)
        }
        log("Required dependencies not found on path. Aborting Test Product Upgradation.");
        gui.rejectWithoutPrompt();
        return;
    }
    // component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Manager/webapp");

}

function install() {
    log("Inside install()");
    log("Starting TestProduct installation wizard ....");
    if (execute("ls " + installerRPM)[1] == 0) {
        if (verifyRPMPackage()) {
            log(installerRPM + " version and release matched with Version:" + installer.value("InstallerVersion") + " Release:" + installer.value("InstallerBuild") + "successfully.");
            // We do not require to install fonts, as we are using Selawik web-font 
            // installFonts();
            var command = populateEnvironmentData();
            command += " rpm -ivh --prefix  " + findInstallationPath() + " --nofiledigest " + installerRPM + " --nodeps";
            command += " | tee -a " + findLogFile();
            log("Installing Test Product");
            log(command);
            component.addElevatedOperation("Execute", "/bin/sh", "-c", command);
            log("Completed TestProduct Installation ...");
            installationComplete = true;
        }
    } else {
        log("Could not find " + installerRPM + ". It should be present in the CWD.");
        log("Aborting Installation.");
        if (installer.value("silent") != "true") {
            QMessageBox.critical("product-installer-critical", "Test Product Installer", "Required dependencies not found on path. Aborting Test Product Installation.", QMessageBox.Ok)
        }
        log("Required dependencies not found on path. Aborting Test Product Installation.");
        gui.rejectWithoutPrompt();
        return;
    }
    // rpm -ivh --prefix  $INSTALLPATH --nofiledigest $InstallerRPM --nodeps 
    // component.addElevatedOperation("Execute", "rm", "-Rf", installationPath + "/Manager/webapp");
}

function verifyRPMPackage() {
    var version = execute("rpm -qp --queryformat '%{version}\n' " + installerRPM)[0];
    var release = execute("rpm -qp --queryformat '%{release}\n' " + installerRPM)[0];
    if (installer.value("InstallerVersion") != version || installer.value("InstallerBuild") != release) {
        log(installerRPM + " version or release does not match with Version:" + installer.value("InstallerVersion") + " Release:" + installer.value("InstallerBuild"));
        log("Aborting Installation.");
        if (installer.value("silent") != "true") {
            QMessageBox.critical("product-installer-critical", "Test Product Installer", "Improper information provided while building installer. Aborting Test Product Installation.", QMessageBox.Ok)
        }
        log("Improper information provided while building installer. Aborting Test Product Installation.");
        gui.rejectWithoutPrompt();
        return false;
    } else {
        return true;
    }
}

function uninstall() {
    log("Inside uninstall()");
    var targetDir = installer.value("TargetDir");
    component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", populateEnvironmentData() + " rpm -e TestProduct | tee -a " + findLogFile());
    component.addElevatedOperation("Execute", "pwd", "UNDOEXECUTE", "{0,1,2,3,4,5,15}", "rm", "-rf", targetDir + installer.value("installationFolder"));
}

function validateOptions() {
    if (installer.value("_installationFound") != 'true' && (installer.value('uninstall') == 'true' || installer.value('upgrade') == 'true')) {
        if (installer.value("silent") == 'true') {
            log("No existing Test Product installation found but option (Upgrade/Uninstall) provided in silent mode. Interrupting installation.");
            gui.cancelButtonClicked();
            return false;
        } else {
            if (QMessageBox.critical("product-installer-critical", "Installer", 'No existing Test Product installation found but Upgrade/Uninstall option provided through command line options. Interrupting installation.', QMessageBox.Ok) == QMessageBox.Ok) {
                gui.cancelButtonClicked();
                return false;
            }
        }
    } else {
        return true;
    }
}

function installFonts() {
    if (execute("rpm -qa |grep -w 'msttcore-fonts' > /dev/null")[1] != 0) {
        log("Installing Core Fonts ....");
        var targetDir = installer.value("TargetDir");
        var fontsRPM = targetDir + "/pkg/msttcore-fonts-installer-2.6-1.noarch.rpm";
        var command = "rpm -ivh " + fontsRPM + " | tee -a " + findLogFile();
        log(command);
        component.addElevatedOperation("Execute", "{0,1,2,3,4,5,15}", "/bin/sh", "-c", command);
        log("Core Fonts installed successfully.");
    } else {
        log("Core Fonts already installed.");
    }
}

function execute(command) {
    var resultArr = installer.execute("/bin/sh", new Array("-c", command));
    if (resultArr && resultArr.length > 1) {
        resultArr[0] = resultArr[0].replace(/\r?\n|\r/g, "");
    } else {
        resultArr = ["", 1];
    }
    return resultArr;
}

function populateEnvironmentData() {
    log("Inside populateEnvironmentData()");
    var targetDir = installer.value("TargetDir");
    // component.addElevatedOperation("Execute", "mkdir", targetDir + "/TestProduct");
    var command = "export PRODUCT_INSTALLPATH=" + findInstallationPath() + ";";
    command += "export PRODUCT_MANAGERPORT=" + installer.value("managerPort", "0000") + ";";
    command += "export PRODUCT_MONITORPORT=" + installer.value("monitorPort", "0000") + ";";
    command += "export PRODUCT_SERVICEPORT=" + installer.value("smPort", "0000") + ";";
    command += "export PRODUCT_DBPORT=" + installer.value("dbPort", "0000") + ";";
    command += "export PRODUCT_DBLOCATION=" + installer.value("dbPath", "") + ";";
    command += "export PRODUCT_INSTALLMANAGER=" + installer.value("installationRequested_test.product.manager") + ";";
    command += "export PRODUCT_INSTALLMONITOR=" + installer.value("installationRequested_test.product.monitor") + ";";
    command += "export PRODUCT_INSTALLDB=" + installer.value("installationRequested_test.product.db") + ";";
    command += "export PRODUCT_INSTALLFOLDER=TestProduct;";
    command += "export PRODUCT_INSTALLATIONPATH=" + findInstallationPath() + ";";
    log(command);
    return command;
}

function findInstallationPath() {
    var targetDir = installer.value("TargetDir");
    var installationFolder = installer.value("installationFolder");
    return targetDir.substring(0, targetDir.indexOf(installationFolder) > -1 ? targetDir.indexOf(installationFolder) : targetDir.length);
}

function findInstallationHomeFolder() {
    var location = installer.value("TargetDir");
    if (location.endsWith(installer.value("installationFolder"))) {
        return location;
    } else {
        return location + installer.value("installationFolder");
    }
}

function findLogFile() {
    return installer.value("logPath") + "/" + installer.value("logFile");
}

function getConfProperty(key) {
    var line = installer.execute("grep", new Array(key + "=", installer.value("systemConfigFilePath")))[0];
    if (line) {
        var parts = line.split("=");
        if (parts.length > 1) {
            return (parts[1]).replace(/\r?\n|\r/g, "");
        }
    }
    return undefined;
}

function findServicePortFromWrapperConf(wrapperConf) {
    log("Looking port in Wrapper.conf : " + wrapperConf);
    if (installer.fileExists(wrapperConf)) {
        var command = "grep wrapper.app.parameter.2 " + wrapperConf;
        var line = installer.execute("/bin/sh", new Array("-c", command))[0];
        if (line) {
            line = line.replace(/\r?\n|\r/g, "");
            var parts = line.split("=");
            if (parts.length > 1) {
                log("Port found ( " + parts[1] + " ) in " + wrapperConf);
                return parts[1].trim();
            } else {
                log("Unable to find port in line '" + line + "'");
            }
        } else {
            log("Command '" + command + "' returns nothing");
        }
    } else {
        log("Wrapper.conf : " + wrapperConf + " not found.");
    }
    return "0000";
}

function findServicePortFromMonitorConf(monitorCfg) {
    log("Looking port in Monitor.cfg : " + monitorCfg);
    if (installer.fileExists(monitorCfg)) {
        var command = "grep -2 HTTP " + monitorCfg + " | grep port";
        var line = installer.execute("/bin/sh", new Array("-c", command))[0];
        if (line) {
            line = line.replace(/\r?\n|\r/g, "");
            var parts = line.split("=");
            if (parts.length > 1) {
                log("Port found ( " + parts[1] + " ) in " + monitorCfg);
                return parts[1].trim();
            } else {
                log("Unable to find port in line '" + line + "'");
            }
        } else {
            log("Command '" + command + "' returns nothing");
        }
    } else {
        log("Monitor.cfg : " + monitorCfg + " not found.");
    }
    return "0000";
}

function log(msg) {
    console.log(msg);
    installer.execute("/bin/sh", new Array("-c", "echo '" + msg + "' >> " + installer.value("logPath") + "/" + installer.value("logFile")));
}
