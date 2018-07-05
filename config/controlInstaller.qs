//Ref :: gui :: https://doc.qt.io/qtinstallerframework/scripting-gui.html#reject-method
//Ref :: installer :: http://doc.qt.io/qtinstallerframework/scripting-installer.html
//Ref :: component :: http://doc.qt.io/qtinstallerframework/scripting-component.html
//Ref :: Component :: http://doc.qt.io/qtinstallerframework/qinstaller-component.html
//Ref :: Package :: http://doc.qt.io/qtinstallerframework/ifw-component-description.html
//Ref :: Configuration :: http://doc.qt.io/qtinstallerframework/ifw-globalconfig.html
//Ref :: QInstaller :: http://doc.qt.io/qtinstallerframework/scripting-qinstaller.html
//Ref :: Operations :: http://doc.qt.io/qtinstallerframework/operations.html
//Ref :: QMessageBox :: http://doc.qt.io/qt-5/qmessagebox.html
//Ref :: buttons :: http://doc.qt.io/qtinstallerframework/scripting-buttons.html
//Ref :: Scripting :: https://doc.qt.io/qtinstallerframework/scripting-qmlmodule.html
//Ref :: Controller :: http://ifw.podsvirov.pro/qtifw/doc/noninteractive.html
//Ref :: PackageManagerPage :: http://doc.qt.io/qtinstallerframework/qinstaller-packagemanagerpage.html

var systemConfigFilePath = "/qtDemoProject.conf";
var versionKey = "prod.version";
var osKey = "prod.plateform";
var buildKey = "prod.build";
var installationPathKey = "prod.path";
var version, release, path;
var installationFound = false;
var prodFolder = "/QTDemoInstaller";
var tempInstallationPath = "/tmp" + prodFolder;
var maintenanceTool = "QTDemoInstallerMaintenanceTool";
var requiredMinDiskSpace = 0.1; //In GB
var availableDiskSpace = 0; //In GB
var selectedPath;
var uninstallationCalled = false;
var _showInfoDialogClosed;
var _leaveAbortInstallationPageConnected = false;
var _onLeftAbortInstallationPageCalled = false
var installerInUpgradationMode = false;
var _isInterrupted = false;
var autoClickDelay = 500;
var logFile = "QTDemoInstallation.log";
var rootUserRequired = false;

// Command line options for silent installation
var isSilent = false;                       // Optional (true) default : false
var isUpgrade = false;                      // Optional (true) default : false
var isUninstall = false;                    // Optional (true) default : false
var delegatedUninstall = false;             // Optional (true) default : false
var installationPath;                       // Optional (<TargetDir>) default : /usr/local/QTDemoInstaller
var installModule4;                         // Optional (true, false) default : true
var installModule5;                         // Optional (true, false) default : true
var installModule1;                         // Optional (true, false) default : true
var module1Port;                            // Optional (<Module1Port>) default : 1234
var module7Port;                            // Optional (<Module7Port>) default : 2345
var module4Port;                            // Optional (<Module4Port>) default : 3456
var module5Port;                            // Optional (<Module5Port>) default : 4567
var logPath;                                // Optional (<LogDir>) default : <CurrentDir>

//ProductVersion format in config.xml => major.minor.patch|build|branch|other

function Controller() {
    logPath = installer.execute("pwd")[0].replace(/\r?\n|\r/g, "");
    systemConfigFilePath = installer.value("HomeDir") + systemConfigFilePath; 
    log("Logging file : " + logPath + "/" + logFile);
    log("Going to install QT Demo Installer version : " + installer.value("ProductInstallerVersion"));
    populateCommandLineArguments();
    log("Inside QT Demo Installer Controller()");
    _showInfoDialogClosed = QMessageBox.Ok;
    populateInstallerInfo();
    installer.setValue("systemConfigFilePath", systemConfigFilePath);
    installer.setValue("versionKey", versionKey);
    installer.setValue("buildKey", buildKey);
    installer.setValue("osKey", osKey);
    installer.setValue("installationPathKey", installationPathKey);
    installer.setValue("tempInstallationPath", tempInstallationPath);
    if (isSilent) {
        installer.autoAcceptMessageBoxes();
        installer.setMessageBoxAutomaticAnswer("OverwriteTargetDirectory", QMessageBox.Yes);
    }
    var widget = gui.pageById(QInstaller.Introduction);
    if (widget != null) {
        widget.packageManagerCoreTypeChanged.connect(onChangePackageManagerCoreType);
    }

    widget = gui.pageById(QInstaller.TargetDirectory);
    if (widget != null) {
        widget.left.connect(onLeftTargetDirectoryPage);
    }

    widget = gui.pageById(QInstaller.ComponentSelection);
    if (widget != null) {
        widget.left.connect(onLeftComponentSelectionPage);
    }

    widget = gui.pageById(QInstaller.PerformInstallation);
    if (widget != null) {
        // widget.left.connect(onInstallationCompletion);
    }

    // This being connected from callback function
    // gui.pageByObjectName("DynamicAbortInstallationPage").left.connect(onLeftAbortInstallationPage);

    gui.interrupted.connect(onInstallationInterrupted);
    installer.installationStarted.connect(onInstallationStarted);
    installer.installationFinished.connect(onInstallationFinished);
    installer.installationInterrupted.connect(onInstallationInterrupted);
    installer.uninstallationStarted.connect(this, onUninstallationStarted);
    installer.uninstallationFinished.connect(this, onUninstallationFinished);
    installer.finishButtonClicked.connect(onLeftFinishedPage);
}

Controller.prototype.IntroductionPageCallback = function () {
    log("Inside Controller.IntroductionPageCallback()");
    var widget = gui.currentPageWidget();
    if (widget != null) {
        if (installer.isInstaller()) {
            widget.title = "Setup - QT Demo Installer";
            widget.MessageLabel.setText("Welcome to the QT Demo Installer Installation Wizard.");
        } else {
            var radioButton = widget.findChild("UpdaterRadioButton");
            radioButton.setVisible(false);
            radioButton = widget.findChild("PackageManagerRadioButton");
            radioButton.setVisible(false);
        }
    }
    validateUser();
    if (installer.isInstaller()) {
        checkOldInstallation();
    } else if (installer.isUninstaller() && delegatedUninstall) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

Controller.prototype.DynamicAbortInstallationPageCallback = function () {
    log("Inside Controller.prototype.DynamicAbortInstallationPageCallback()");

    var page = gui.pageWidgetByObjectName("DynamicAbortInstallationPage");

    //Once any of two options (Uninstall/Upgrade) selected, do not allow to change option
    if (page.upgrade.visible && (delegatedUninstall || installerInUpgradationMode)) {
        gui.clickButton(buttons.NextButton, 5);
    }

    if (installer.value("_nonRootUser") == "true") {
        // page.launchTool.setVisible(false);
        page.uninstall.setVisible(false);
        page.upgrade.setVisible(false);
        var html = "Installer must be run as root.<br/><br/>";
        html += "Aborting current QT Demo Installer installation";
        page.abortDetails.html = html;
        skipAllSteps();
    } else if (installer.value("_installationFound")) {

        if (isSilent && !isUpgrade && !isUninstall) {
            log("Other QT Demo installation found and no option (Upgrade/Uninstall) provided in silent mode. Interrupting installation.");
            gui.cancelButtonClicked();
            return;
        }
        page.uninstall.setVisible(true);

        if (fileExists(path + "/" + maintenanceTool)) {
            if (version < installer.value("ProductInstallerVersion") && release < installer.value("QTDemoInstallerBuild")) {
                // Case 1 : If Conf file and Maintenance tool both present and lower version QT Demo installed
                var html = "QT Demo Installer already installed.<br/><br/>";
                html += "<b>Installation Directory :</b> " + path + "<br/>";
                html += "<b>Installer Version :</b> " + installer.value("ProductInstallerVersion") + "<br/>";
                html += "<b>Installer Release :</b> " + installer.value("QTDemoInstallerBuild") + "<br/><br/><br/>";
                html += "A lower version of QT Demo " + version + "-" + release + " is installed<br/><br/>";
                html += "Select appropriate action to be performed";
                page.upgrade.setVisible(true);
                page.abortDetails.html = html;
                if (isUpgrade) {
                    page.upgrade.setChecked(true);
                }
            } else {
                // Case 3 : If Conf file and Maintenance tool both present but installed version is same or higher
                var html = "QT Demo Installer already installed.<br/><br/>";
                html += "<b>Installation Directory :</b> " + path + "<br/>";
                html += "<b>Installer Version :</b> " + installer.value("ProductInstallerVersion") + "<br/>";
                html += "<b>Installer Release :</b> " + installer.value("QTDemoInstallerBuild") + "<br/><br/><br/>";
                html += "A higher or same version of QT Demo " + version + "-" + release + " is already installed<br/><br/>";
                html += "To install an older or same version of QT Demo, uninstall the existing version first";
                page.upgrade.setVisible(false);
                page.abortDetails.html = html;
            }
        } else {
            // Case 2 : If Conf file present but Maintenance tool is not there
            var html = "QT Demo Installer already installed.<br/><br/>";
            html += "<b>Installation Directory :</b> " + path + "<br/>";
            html += "<b>Installed Version :</b> " + version + "<br/>";
            html += "<b>Installed Release :</b> " + release + "<br/><br/><br/>";
            html += "QT Demo installation found but either QT Demo is not installed properly or some files got deleted.<br/><br/>";
            html += "Please reinstall the QT Demo Installer";
            page.upgrade.setVisible(false);
            page.abortDetails.html = html;
        }
        enableUpgaradtionSteps();
    } else {
        // page.launchTool.setVisible(false);
        page.uninstall.setVisible(false);
        page.upgrade.setVisible(false);
        var html = "Installation aborted due to unknown reason";
        page.abortDetails.html = html;
        skipAllSteps();
    }
    if (!page.upgrade.visible && isUpgrade) {
        if (installer.value("silent") == 'true') {
            log("Upgrade option provided through command line options in silent mode. But Upgarde operation not supported. Interrupting installation.");
            gui.cancelButtonClicked();
            return false;
        } else {
            if (QMessageBox.critical("installer-critical", "Installer", 'Upgrade option provided through command line options. But Upgarde operation not supported. Interrupting installation.', QMessageBox.Ok) == QMessageBox.Ok) {
                gui.cancelButtonClicked();
                return false;
            }
        }
    }

    if (isUninstall) {
        page.uninstall.setChecked(true);
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

function onLeftAbortInstallationPage() {
    log("Inside onLeftAbortInstallationPage(), _isInterrupted : " + _isInterrupted);
    if (_isInterrupted) {
        return;
    }
    if (!_onLeftAbortInstallationPageCalled) {
        _onLeftAbortInstallationPageCalled = true;
    } else {
        return;
    }

    var widget = gui.pageWidgetByObjectName("DynamicAbortInstallationPage");
    if (installer.value("_nonRootUser") == 'true') {
        return;
    }
    if (widget != null) {
        if (widget.uninstall.checked) {
            log("User selected Uninstallation for QT Demo");
            // skipAllSteps();
            // installer.setUninstaller();
            delegatedUninstall = true;
            installerInUpgradationMode = false;
            installer.setValue("installerInUpgradationMode", "false");
            launchMaintenanceTool();
        }
        if (widget.upgrade.checked) {
            log("User selected Upgradation for QT Demo");
            installerInUpgradationMode = true;
            delegatedUninstall = false;
            installer.setValue("installerInUpgradationMode", "true");
            installer.setValue("TargetDir", tempInstallationPath);

            var components = installer.components();
            for (i = 0; i < components.length; ++i) {
                var installationRequested = getConfProperty(components[i].name);
                installer.setValue("installationRequested_" + components[i].name, installationRequested ? installationRequested : "false");
            }

            if (installerInUpgradationMode) {
                var result = installer.executeDetached("/bin/sh", new Array("-c", "rm -Rf " + tempInstallationPath + "/" + maintenanceTool));
                result = installer.executeDetached("/bin/sh", new Array("-c", "rm -Rf " + tempInstallationPath + "/" + maintenanceTool + ".ini"));
                result = installer.executeDetached("/bin/sh", new Array("-c", "rm -Rf " + tempInstallationPath + "/" + maintenanceTool + ".dat"));
                result = installer.executeDetached("/bin/sh", new Array("-c", "rm -Rf /tmp/" + maintenanceTool + "*.lock"));
                result = installer.executeDetached("/bin/sh", new Array("-c", "rm -Rf " + tempInstallationPath));
            }
            // enableUpgaradtionSteps();
        }
    }
}

Controller.prototype.TargetDirectoryPageCallback = function () {
    log("Inside Controller.prototype.TargetDirectoryPageCallback()");
    if (installationPath) {
        installer.setValue("TargetDir", installationPath)
    }
    var widget = gui.currentPageWidget();
    if (widget != null) {
        if (installer.value("insufficientDiskSpace") === "true") {
            widget.WarningLabel.setText("Only " + availableDiskSpace + " GB space is available in this directory. Installation directory should have a minimum of " + requiredMinDiskSpace + " GB space available.\n\nPlease specify a valid installation directory.");
        } else if (installer.value("invalidTargetPath") === "true") {
            widget.WarningLabel.setText("Invalid path selected. Path " + selectedPath + " does not exists.");
        } else {
            widget.WarningLabel.setText("");
        }
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

function onLeftTargetDirectoryPage() {
    log("Inside onLeftTargetDirectoryPage(), _isInterrupted : " + _isInterrupted);
    if (_isInterrupted) {
        return;
    }
    var widget = gui.pageById(QInstaller.TargetDirectory);
    if (widget != null) {
        selectedPath = installer.value("TargetDir");
        if (selectedPath.endsWith(prodFolder)) {
            selectedPath = selectedPath.substr(0, selectedPath.lastIndexOf(prodFolder));
        }
        if (!installer.fileExists(selectedPath)) {
            installer.setValue("invalidTargetPath", "true");
            installer.setValue("insufficientDiskSpace", "false");

            if (isSilent) {
                log("Invalid target directory provided in silent mode. Interrupting installation.");
                gui.cancelButtonClicked();
                return;
            } else {
                gui.clickButton(buttons.BackButton, autoClickDelay);
                return;
            }
        } else {
            installer.setValue("invalidTargetPath", "false");
            installer.setValue("TargetDir", selectedPath + prodFolder);
        }
        availableDiskSpace = availablesSpaceInDirectory(selectedPath);
        availableDiskSpace = availableDiskSpace / (1024 * 1024);
        availableDiskSpace = parseFloat(Math.round(availableDiskSpace * 100) / 100);
        log("Inside onLeftTargetDirectoryPage(), available space in " + selectedPath + " is " + availableDiskSpace);
        if (availableDiskSpace < requiredMinDiskSpace) {
            installer.setValue("insufficientDiskSpace", "true");
            if (isSilent) {
                log("Insufficient Disk Space in provided target directory in silent mode. Interrupting installation.");
                gui.cancelButtonClicked();
            } else {
                gui.clickButton(buttons.BackButton, autoClickDelay);
            }
        } else {
            installer.setValue("insufficientDiskSpace", "false");
        }
    }
}

Controller.prototype.ComponentSelectionPageCallback = function () {
    log("Inside Controller.prototype.ComponentSelectionPageCallback()");
    var components = installer.components();
    var rootComp = null;
    for (i = 0; i < components.length; ++i) {
        if (components[i].installationRequested() && components[i].name == 'com.org.product.module1') {
            if (installer.removeWizardPage(components[i], "Module1ConfigurationPage")) {
                log("WizardPage Module1ConfigurationPage removed.");
            }
        } else if (components[i].installationRequested() && components[i].name == 'com.org.product.module7') {
            if (installer.removeWizardPage(components[i], "Module7ConfigurationPage")) {
                log("WizardPage Module7ConfigurationPage removed.");
            }
        } else if (components[i].installationRequested() && components[i].name == 'com.org.product.module4') {
            if (installer.removeWizardPage(components[i], "Module4ConfigurationPage")) {
                log("WizardPage Module4ConfigurationPage removed.");
            }
        } else if (components[i].installationRequested() && components[i].name == 'com.org.product.module5') {
            if (installer.removeWizardPage(components[i], "Module5ConfigurationPage")) {
                log("WizardPage Module5ConfigurationPage removed.");
            }
        } else if (components[i].name == 'com.org.product') {
            if (installer.removeWizardPage(components[i], "InstallationDetailsPage")) {
                log("WizardPage InstallationDetailsPage removed.");
            }
        }
    }
    var widget = gui.currentPageWidget();
    if (installModule1 && installModule1 == 'true') {
        widget.selectComponent('com.org.product.module1');
    }
    if (installModule1 && installModule1 == 'false') {
        widget.deselectComponent('com.org.product.module1');
    }
    if (installModule4 && installModule4 == 'true') {
        widget.selectComponent('com.org.product.module4');
    }
    if (installModule4 && installModule4 == 'false') {
        widget.deselectComponent('com.org.product.module4');
    }
    if (installModule5 && installModule5 == 'true') {
        widget.selectComponent('com.org.product.module5');
    }
    if (installModule5 && installModule5 == 'false') {
        widget.deselectComponent('com.org.product.module5');
    }

    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

function onLeftComponentSelectionPage() {
    log("Inside onLeftComponentSelectionPage(), _isInterrupted : " + _isInterrupted);
    if (_isInterrupted) {
        return;
    }
    var components = installer.components();
    var rootComp = null;
    for (i = 0; i < components.length; ++i) {
        installer.setValue("installationRequested_" + components[i].name, components[i].installationRequested() + "");

        if (components[i].installationRequested() && components[i].name == 'com.org.product.module1') {
            if (!installer.addWizardPage(components[i], "Module1ConfigurationPage", QInstaller.ReadyForInstallation)) {
                log("Could not load Module1ConfigurationPage. Using default port value.");
            }
        } else if (components[i].installationRequested() && components[i].name == 'com.org.product.module7') {
            if (!installer.addWizardPage(components[i], "Module7ConfigurationPage", QInstaller.ReadyForInstallation)) {
                log("Could not load Module7ConfigurationPage. Using default port value.");
            }
        } else if (components[i].installationRequested() && components[i].name == 'com.org.product.module4') {
            if (!installer.addWizardPage(components[i], "Module4ConfigurationPage", QInstaller.ReadyForInstallation)) {
                log("Could not load Module4ConfigurationPage. Using default port value.");
            }
        } else if (components[i].installationRequested() && components[i].name == 'com.org.product.module5') {
            if (!installer.addWizardPage(components[i], "Module5ConfigurationPage", QInstaller.ReadyForInstallation)) {
                log("Could not load Module5ConfigurationPage. Using default port value.");
            }
        } else if (components[i].name == 'com.org.product') {
            installer.addWizardPage(components[i], "InstallationDetailsPage", QInstaller.ReadyForInstallation);
        }
    }
}

Controller.prototype.LicenseAgreementPageCallback = function () {
    log("Inside Controller.LicenseAgreementPageCallback()");

    if (isSilent) {
        gui.currentPageWidget().findChild("AcceptLicenseRadioButton").checked = true;
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

Controller.prototype.DynamicModule7ConfigurationPageCallback = function () {
    log("Inside Controller.prototype.DynamicModule7ConfigurationPageCallback()");
    var component = gui.pageWidgetByObjectName("DynamicModule7ConfigurationPage");
    if (module7Port) {
        component.module7Port.setText(module7Port);
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

Controller.prototype.DynamicModule1ConfigurationPageCallback = function () {
    log("Inside Controller.prototype.DynamicModule1ConfigurationPageCallback()");
    var component = gui.pageWidgetByObjectName("DynamicModule1ConfigurationPage");
    if (module1Port) {
        component.module1Port.setText(module1Port);
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

Controller.prototype.DynamicModule4ConfigurationPageCallback = function () {
    log("Inside Controller.prototype.DynamicModule4ConfigurationPageCallback()");
    var component = gui.pageWidgetByObjectName("DynamicModule4ConfigurationPage");
    if (module4Port) {
        component.module4Port.setText(module4Port);
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton);
    }
}

Controller.prototype.DynamicModule5ConfigurationPageCallback = function () {
    log("Inside Controller.prototype.DynamicModule5ConfigurationPageCallback()");
    var component = gui.pageWidgetByObjectName("DynamicModule5ConfigurationPage");
    if (module5Port) {
        component.module5Port.setText(module5Port);
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

Controller.prototype.DynamicInstallationDetailsPageCallback = function () {
    log("Inside Controller.DynamicInstallationDetailsPageCallback()");
    if (installerInUpgradationMode || delegatedUninstall) {
        populateUpgradationDetails();
    } else {
        populateInstallationDetails();
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

Controller.prototype.ReadyForInstallationPageCallback = function () {
    log("Inside Controller.ReadyForInstallationPageCallback()");
    if (installer.isUninstaller()) {
        installer.setValue("uninstallationRequested_com.org.product", "true");
        installer.setValue("uninstallationRequested_com.interra.commons", "true");
        installer.setValue("uninstallationRequested_com.org.product.module7", "true");
        installer.setValue("uninstallationRequested_com.org.product.module4", "true");
        installer.setValue("uninstallationRequested_com.org.product.module5", "true");
        installer.setValue("uninstallationRequested_com.org.product.module1", "true");
        installer.setValue("uninstallationRequested_com.org.product.module2", "true");
        installer.setValue("uninstallationRequested_com.org.product.module6", "true");
        installer.setValue("uninstallationRequested_com.org.product.module3", "true");
        if (delegatedUninstall) {
            gui.clickButton(buttons.NextButton, autoClickDelay);
            return;
        }
    }
    if (installerInUpgradationMode) {
        var widget = gui.currentPageWidget();
        if (widget != null) {
            widget.title = "Ready to upgrade";
            widget.MessageLabel.setText("Setup is now ready to begin upgrading QT Demo Installer on your computer. Do not interrupt process, as interruption may corrupt existing installation.");
        }
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

Controller.prototype.PerformInstallationPageCallback = function () {
    log("Inside Controller.prototype.PerformInstallationPageCallback()");
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

Controller.prototype.FinishedPageCallback = function () {
    log("Inside Controller.prototype.FinishedPageCallback()");
    var widget = gui.currentPageWidget();
    if (widget != null) {
        widget.title = "Completing the QT Demo Installation Wizard";
        if (installer.isInstaller() && installer.value('installationRequested_com.org.product.module5') == 'true') {
            var html = "System reboot required for proper installation. On click of Finish, system will be rebooted automatically.<br><br>";
            html += "Click Finish to exit the QT Demo Installer Wizard.";
            widget.MessageLabel.setText(html);
        }
    }
    if (isSilent) {
        gui.clickButton(buttons.FinishButton, autoClickDelay);
    }
}

function onLeftFinishedPage() {
    log("onLeftFinishedPage called");
    if (installer.isInstaller() && installer.value('installationRequested_com.org.product.module5') == 'true') {
        // log("Going to restart system");
        // installer.executeDetached("shutdown", "-r", "+1", "System will restart in 1 minute. Please save your work.");
    }
}

function checkOldInstallation() {
    log("Inside Controller checkOldInstallation()");
    log("Looking if an QT Demo installation already exists on this machine ....");
    if (installationFound = fileExists(systemConfigFilePath)) {
        log("Configuration file : " + systemConfigFilePath + " exists");
        log("Operating System : " + (getConfProperty(osKey)));
        log("Installed Version : " + (version = getConfProperty(versionKey)));
        log("Installed Release : " + (release = getConfProperty(buildKey)));
        log("QT Demo Installation Path : " + (path = getConfProperty(installationPathKey)));
        if (version || release || path) {
            log("Found an existing QT Demo Installation.");
            installer.setValue("_installationFound", installationFound);
        }
        installer.setValue("existingInstallationPath", path);
        //log("Using flag _installationFound QT Demo Component will launch AbortInstallationPage");
    } else {
        log("Configuration file : " + systemConfigFilePath + " not exists");
    }
}

function fileExists(filePath) {
    var status = installer.execute("ls", filePath, ">> /dev/null")[1];
    if (status == 0) {
        return true;
    } else {
        return false;
    }
}

function getConfProperty(key) {
    var line = installer.execute("grep", new Array(key, systemConfigFilePath))[0];
    if (line) {
        var parts = line.split("=");
        if (parts.length > 1) {
            return (parts[1]).replace(/\r?\n|\r/g, "");
        }
    }
    return undefined;
}

function availablesSpaceInDirectory(folderPath) {
    // df -Pk /usr/local | tail -1 | awk '{print $4}'
    // echo $(df -Pk /usr/local | tail -1 | awk '{print $4}')
    var resultArr = installer.execute("/bin/sh", new Array("-c", "df -Pk " + folderPath + " | tail -1 | awk '{print $4}'"));
    if (resultArr && resultArr.length > 1 && resultArr[1] == 0) {
        return resultArr[0].replace(/\r?\n|\r/g, "");
    }
    return undefined;
}

function skipAllSteps() {
    installer.setDefaultPageVisible(QInstaller.TargetDirectory, false);
    installer.setDefaultPageVisible(QInstaller.ComponentSelection, false);
    installer.setDefaultPageVisible(QInstaller.LicenseCheck, false);
    installer.setDefaultPageVisible(QInstaller.StartMenuSelection, false);
    installer.setDefaultPageVisible(QInstaller.ReadyForInstallation, false);
    installer.setDefaultPageVisible(QInstaller.PerformInstallation, false);
}

function enableUpgaradtionSteps() {
    installer.setDefaultPageVisible(QInstaller.TargetDirectory, false);
    installer.setDefaultPageVisible(QInstaller.ComponentSelection, false);
    installer.setDefaultPageVisible(QInstaller.LicenseCheck, false);
    installer.setDefaultPageVisible(QInstaller.StartMenuSelection, false);
    installer.setDefaultPageVisible(QInstaller.ReadyForInstallation, true);
    installer.setDefaultPageVisible(QInstaller.PerformInstallation, true);

    var components = installer.components();
    for (i = 0; i < components.length; ++i) {
        if (components[i].name == 'com.org.product') {
            installer.addWizardPage(components[i], "InstallationDetailsPage", QInstaller.ReadyForInstallation);
            log("WizardPage InstallationDetailsPage added.");
            break;
        }
    }

    if (!_leaveAbortInstallationPageConnected) {
        _leaveAbortInstallationPageConnected = true;
        log("Connecting onLeftAbortInstallationPage on entered InstallationDetailsPage");
        gui.pageByObjectName("DynamicInstallationDetailsPage").entered.connect(onLeftAbortInstallationPage);
    }
}

function launchMaintenanceTool() {
    log("Launching QT Demo Maintenance Tool");
    if (installer.executeDetached("/bin/sh", new Array("-c", "sleep 0.2 && rm -f /tmp/" + maintenanceTool + "*.lock && " + path + "/" + maintenanceTool + " delegatedUninstall=true silent=" + isSilent))) {
        log("QT Demo Maintenance Tool launched, exiting from installation wizard");
        // gui.reject();
        gui.rejectWithoutPrompt();
    }
}

function showInfoDialog(msg) {
    return QMessageBox.information("installer-info", "Installer", msg, QMessageBox.Ok);
}

function askQuestionDialog(msg) {
    // Ref : http://doc.qt.io/qt-5/qmessagebox-obsolete.html
    // QMessageBox will return clicked button int value
    // Default buttons : NoButton, Ok, Cancel, Yes, No, Abort, Retry, Ignore, YesAll, NoAll
    return QMessageBox.question("installer-question", "Installer", msg, QMessageBox.Ok | QMessageBox.Cancel);
}

function showWarningDialog(msg) {
    return QMessageBox.warning("installer-warning", "Installer", msg, QMessageBox.Ok);
}

function showCriticalDialog(msg) {
    return QMessageBox.critical("installer-critical", "Installer", msg, QMessageBox.Ok);
}

function onChangePackageManagerCoreType() {
    log("Inside onChangePackageManagerCoreType()");
    log("Is Installer: " + installer.isInstaller());
    log("Is Updater: " + installer.isUpdater());
    log("Is Uninstaller: " + installer.isUninstaller());
    log("Is Package Manager: " + installer.isPackageManager());
}

function killServiceByPID(serviceName) {
    //kill -SIGTERM  $(ps -ax | grep Module7Service | head -1 | awk -F' ' '{print $1}')
    var pid = installer.execute("pidof", new Array(serviceName))[0];
    if (pid && parseInt(pid) > 0) {
        installer.execute("kill", new Array("-SIGTERM", pid));
    }
}

function onInstallationInterrupted() {
    log("Inside onInstallationInterrupted()");
    _isInterrupted = true;
    if (installerInUpgradationMode || delegatedUninstall) {
        return;
    }

    log("Interruption Reason : " + installer.value("_interruptReason"));
    if (installer.isInstaller() && !uninstallationCalled) {
        log("Installer was running in Installer mode and interrupted. So uninstalling any partially installed components");

        //Stop any running services for different components
        uninstallModule6();
        uninstallModule1();
        uninstallModule3();
        uninstallModule7();
        uninstallModule4();
        uninstallModule5();
        uninstallModule2();
        uninstallQTDemo();

        onUninstallationFinished(true);
        uninstallationCalled = true;
    }
}

function onUninstallationStarted() {
    log("Inside onUninstallationStarted()");

    if (installer.value("installerInUpgradationMode") == "true") {
        return;
    }

    if (installer.value("uninstallationRequested_com.org.product.module6") == "true") {
        // uninstallModule6();
    }
    if (installer.value("uninstallationRequested_com.org.product.module1") == "true") {
        // uninstallModule1();
    }
    if (installer.value("uninstallationRequested_com.org.product.module3") == "true") {
        // uninstallModule3();
    }
    if (installer.value("uninstallationRequested_com.org.product.module7") == "true") {
        // uninstallModule7();
    }
    if (installer.value("uninstallationRequested_com.org.product.module4") == "true") {
        // uninstallModule4();
    }
    if (installer.value("uninstallationRequested_com.org.product.module5") == "true") {
        // uninstallModule5();
    }
    if (installer.value("uninstallationRequested_com.org.product.module2") == "true") {
        // uninstallModule2();
    }
    if (installer.value("uninstallationRequested_com.org.product.module") == "true") {
        // uninstallQTDemo();
    }
}

function uninstallModule6() {
    log("Inside uninstallModule6()");
    var destDir = installer.value("TargetDir") + "/Module6";
    installer.execute("/bin/sh", new Array(destDir + "/scripts/stop_app.sh"));
    // killServiceByPID("Module6Service");
}

function uninstallQTDemo() {
    log("Inside uninstallQTDemo()");
    var homeDir = installer.value("HomeDir");
    installer.execute("rm", new Array("-f", systemConfigFilePath));
    // installer.execute("sed", new Array("-i", "/launchQTDemoOnFirstRun/d", homeDir + "/.bashrc"));
}

function uninstallModule1() {
    log("Inside uninstallModule1()");
    var destDir = installer.value("TargetDir") + "/Module1";
    // installer.execute("service", new Array("Module1Service", "stop"));
    // killServiceByPID("Module1Service");
    // installer.execute("rm", new Array("-f", "/etc/init.d/Module1Service"));
    // installer.execute("sed", new Array("-i", "/export Module1_HOME=/d", installer.value("HomeDir") + "/.bashrc"));
}

function uninstallModule3() {
    log("Inside uninstallModule3()");
    var destDir = installer.value("TargetDir") + "/Module3";
    // installer.execute("service", new Array("Module1Service2", "stop"));
    // installer.execute("service", new Array("Module1Service1", "stop"));
    // killServiceByPID("Module1Service2");
    // killServiceByPID("Module1Service1");

    // installer.execute("rm", new Array("-f", "/etc/init.d/Module1Service2"));
    // installer.execute("rm", new Array("-f", "/etc/init.d/Module1Service1"));

    // installer.execute("sed", new Array("-i", "/export Module3_HOME=/d", installer.value("HomeDir") + "/.bashrc"));
}

function uninstallModule7() {
    log("Inside uninstallModule7()");
    var destDir = installer.value("TargetDir") + "/Module7";
    // installer.execute("service", new Array("Module7Service", "stop"));
    // killServiceByPID("Module7Service");
    // installer.execute("/bin/sh", new Array(destDir + "/yajsw-stable-11.11/bin/uninstallDaemon.sh"));
    // installer.execute("chkconfig", new Array("--del", "Module7Service"));
    // installer.execute("xdg-desktop-menu", new Array("uninstall", "module7.desktop"));
}

function uninstallModule4() {
    log("Inside uninstallModule4()");
    var destDir = installer.value("TargetDir") + "/Module4";
    // installer.execute("service", new Array("Module4Service", "stop"));
    // killServiceByPID("Module4Service");
    // installer.execute("/bin/sh", new Array(destDir + "/service/yajsw-stable-11.11/bin/uninstallDaemon.sh"));
    // installer.execute("chkconfig", new Array("--del", "Module4Service"));
    // installer.execute("xdg-desktop-menu", new Array("uninstall", "module4.desktop"));
    // installer.execute("xdg-desktop-menu", new Array("uninstall", "module4-user-guide.desktop"));
}

function uninstallModule5() {
    log("Inside uninstallModule5()");
    var destDir = installer.value("TargetDir") + "/Module5";
    // installer.execute("service", new Array("Module5Service", "stop"));
    // killServiceByPID("Module5Service");
    // installer.execute("chkconfig", new Array("--del", "Module5Service"));
    // installer.execute("rm", new Array("-f", "/etc/init.d/Module5Service"));
}

function uninstallModule2() {
    log("Inside uninstallModule2()");
    var homeDir = installer.value("HomeDir");
    var destDir = installer.value("TargetDir") + "/Module2";
    // installer.execute("service", new Array("Module2Service", "stop"));
    // killServiceByPID("Module2Service");
    // installer.execute("chkconfig", new Array("--del", "Module2Service"));
    // installer.execute("rm", new Array("-f", "/etc/init.d/Module2Service"));
    // installer.execute("sed", new Array("-i", "/Module2_HOME/d", homeDir + "/.bashrc"));
}

function installFirstRunScriptForQTDemo() {
    log("Inside installFirstRunScriptForQTDemo()");

    /*

    if (installer.value("installationRequested_com.org.product.module7") != "true") {
        return;
    }

    var destDir = installer.value("TargetDir") + "/Module";
    var homeDir = installer.value("HomeDir");
    installer.execute("chmod", new Array("+x", destDir + "/bin/launchQTDemoOnFirstRun.sh"));

    installer.execute("sed", new Array("-i", "/launchQTDemoOnFirstRun/d", homeDir + "/.bashrc"));

    var script = [];
    script[0] = " function launchQTDemoOnFirstRun()                                  #launchQTDemoOnFirstRun";
    script[1] = " {                                                                 #launchQTDemoOnFirstRun";
    script[2] = "     if [ -e " + destDir + "/bin/launchQTDemoOnFirstRun.sh ]     #launchQTDemoOnFirstRun";
    script[3] = "     then                                                          #launchQTDemoOnFirstRun";
    script[4] = "         bash " + destDir + "/bin/launchQTDemoOnFirstRun.sh      #launchQTDemoOnFirstRun";
    script[5] = "     fi                                                            #launchQTDemoOnFirstRun";
    script[6] = " }                                                                 #launchQTDemoOnFirstRun";
    script[7] = " launchQTDemoOnFirstRun                                             #launchQTDemoOnFirstRun";

    for (counter = 0; counter < 7; counter++) {
        installer.execute("/bin/sh", new Array("-c", "echo '" + script[counter] + "' >> " + homeDir + "/.bashrc"));
    }

    */

}

function onUninstallationFinished(isInterrupted) {
    log("Inside onUninstallationFinished()");

    if (installer.value("installerInUpgradationMode") == "true") {
        // installer.executeDetached("service Module7Service start");
        if (isSilent) {
            gui.clickButton(buttons.NextButton, autoClickDelay);
            gui.clickButton(buttons.FinishButton, autoClickDelay);
        }
        return;
    }

    var destDir = installer.value("TargetDir");

    if (isInterrupted || installer.value("uninstallationRequested_com.org.product.module6") == "true") {
        installer.execute("rm", new Array("-Rf", destDir + "/Module6"));
    }
    if (isInterrupted || installer.value("uninstallationRequested_com.org.product.module1") == "true") {
        installer.execute("rm", new Array("-Rf", destDir + "/Module1"));
    }
    if (isInterrupted || installer.value("uninstallationRequested_com.org.product.module3") == "true") {
        installer.execute("rm", new Array("-Rf", destDir + "/Module3"));
    }
    if (isInterrupted || installer.value("uninstallationRequested_com.org.product.module7") == "true") {
        installer.execute("rm", new Array("-Rf", destDir + "/Module7"));
    }
    if (isInterrupted || installer.value("uninstallationRequested_com.org.product.module4") == "true") {
        installer.execute("rm", new Array("-Rf", destDir + "/Module4"));
    }
    if (isInterrupted || installer.value("uninstallationRequested_com.org.product.module5") == "true") {
        /*
        if (installer.fileExists(destDir + "/Module5/lib/libwrap.so")) {
            installer.gainAdminRights();
            var currentDir = installer.execute("pwd")[0].replace(/\r?\n|\r/g, "");
            installer.execute("cd", new Array(destDir + "/Module5/lib"));
            installer.execute("unlink", new Array("libwrap.so"));
            installer.execute("rm", new Array("f", "libwrap.so"));
            installer.execute("cd", new Array(currentDir));
            installer.execute("rm", new Array("-Rf", destDir + "/Module5/lib"));
            installer.dropAdminRights();
        }
        */
        installer.execute("rm", new Array("-Rf", destDir + "/Module5"));
    }
    if (isInterrupted || installer.value("uninstallationRequested_com.org.product.module2") == "true") {
        installer.execute("rm", new Array("-Rf", destDir + "/Module2"));
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
        gui.clickButton(buttons.FinishButton, autoClickDelay);
    }
}

function onInstallationStarted() {
    log("Inside onInstallationStarted()");
}

function onInstallationFinished() {
    log("Inside onInstallationFinished()");
    var targetDir = installer.value("TargetDir");
    var installationPath = installer.value("existingInstallationPath");

    if (installer.value("installerInUpgradationMode") == "true") {
        // installer.executeDetached("service Module7Service start");
        installer.execute("cp", targetDir + "InstallationLog.txt", installationPath + "InstallationLog.txt");

        if (isSilent) {
            gui.clickButton(buttons.NextButton, autoClickDelay);
            gui.clickButton(buttons.FinishButton, autoClickDelay);
        }
        return;
    }

    var targetDir = installer.value("TargetDir");
    if (installer.isInstaller() && installer.value("installationRequested_com.org.product.module7") == "true") {
        // log("Starting Module7");
        // log("Execute java -jar " + targetDir + "/Module7/lib/Config.jar startOSMService " + targetDir + "/Module7 ");
        // installer.executeDetached("java", new Array("-jar", targetDir + "/Module7/lib/Config.jar", "startOSMService", targetDir + "/Module7"));
        // log("QT Demo Service Manager started");
        installFirstRunScriptForQTDemo();
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
        gui.clickButton(buttons.FinishButton, autoClickDelay);
    }
}

function validateUser() {
    log("Inside Controller validateUser()");
    if (!rootUserRequired) {
        return;
    }
    var userId = installer.execute("id", "-u")[0].replace(/\r?\n|\r/g, "");
    if (userId + "" != "0") {
        log("Installer must be run as root. Aborting installation");
        installer.setValue("_nonRootUser", "true");
        // log("Using flag _nonRootUser QT Demo Component will launch AbortInstallationPage");
    } else {
        installer.setValue("_nonRootUser", "false");
        // installer.execute("export", "XDG_RUNTIME_DIR=/run/user/0");
        // Above line may resolve below issue 
        // QStandardPaths: wrong ownership on runtime directory /run/user/1000, 1000 instead of 0
    }
}

function populateInstallationDetails() {
    log("Inside Controller populateInstallationDetails()");
    var page = gui.pageWidgetByObjectName("DynamicInstallationDetailsPage");
    var html = "<b>Installation Directory :</b> " + installer.value("TargetDir") + "<br/><br/>";
    log("Installation Directory : " + installer.value("TargetDir"));
    html = html + "<b>QT Demo Components to be installed</b><ul>";
    log("Below QT Demo Components going to be installed :- ");
    var components = installer.components();
    var compCounter = 1;
    for (i = 0; i < components.length; ++i) {
        if (components[i].installationRequested() && components[i].name == 'com.org.product.module1') {
            var compPage = gui.pageWidgetByObjectName("DynamicModule1ConfigurationPage");
            if (!compPage) {
                installer.setValue("module1Port", "0000");
            } else if (compPage.module1Port.text) {
                installer.setValue("module1Port", compPage.module1Port.text);
            } else {
                installer.setValue("module1Port", compPage.module1Port.placeholderText);
            }
            log("\t " + (compCounter++) + " - " + components[i].displayName + " : on port " + installer.value("module1Port", "0000"));
            html = html + "<li>" + components[i].displayName + " on port : " + installer.value("module1Port", "0000") + "</li>";
        } else if (components[i].installationRequested() && components[i].name == 'com.org.product.module7') {
            var compPage = gui.pageWidgetByObjectName("DynamicModule7ConfigurationPage");
            if (!compPage) {
                installer.setValue("module7Port", "0000");
            } else if (compPage.module7Port.text) {
                installer.setValue("module7Port", compPage.module7Port.text);
            } else {
                installer.setValue("module7Port", compPage.module7Port.placeholderText);
            }
            log("\t " + (compCounter++) + " - " + components[i].displayName + " on port : " + installer.value("module7Port", "0000"));
            html = html + "<li>" + components[i].displayName + " on port : " + installer.value("module7Port", "0000") + "</li>";
        } else if (components[i].installationRequested() && components[i].name == 'com.org.product.module4') {
            var compPage = gui.pageWidgetByObjectName("DynamicModule4ConfigurationPage");
            if (!compPage) {
                installer.setValue("module4Port", "0000");
            } else if (compPage.module4Port.text) {
                installer.setValue("module4Port", compPage.module4Port.text);
            } else {
                installer.setValue("module4Port", compPage.module4Port.placeholderText);
            }
            log("\t " + (compCounter++) + " - " + components[i].displayName + " on port : " + installer.value("module4Port", "0000"));
            html = html + "<li>" + components[i].displayName + " on port : " + installer.value("module4Port", "0000") + "</li>";
        } else if (components[i].installationRequested() && components[i].name == 'com.org.product.module5') {
            var compPage = gui.pageWidgetByObjectName("DynamicModule5ConfigurationPage");
            if (!compPage) {
                installer.setValue("module5Port", "0000");
            } else if (compPage.module5Port.text) {
                installer.setValue("module5Port", compPage.module5Port.text);
            } else {
                installer.setValue("module5Port", compPage.module5Port.placeholderText);
            }
            log("\t " + (compCounter++) + " - " + components[i].displayName + " on port : " + installer.value("module5Port", "0000"));
            html = html + "<li>" + components[i].displayName + " on port : " + installer.value("module5Port", "0000") + "</li>";
        } else if (components[i].installationRequested()) {
            log("\t " + (compCounter++) + " - " + components[i].displayName);
            // html = html + "<li>" + components[i].displayName + "</li>";
        }
    }
    html = html + "</ul>";
    page.installationDescription.html = html;
}

function populateUpgradationDetails() {
    log("Inside Controller populateUpgradationDetails()");
    var page = gui.pageWidgetByObjectName("DynamicInstallationDetailsPage");
    //page.setProperty("windowTitle", "QT Demo Upgradation Details");
    //page.label.setProperty("message", "QT Demo Upgradation Details");
    page.windowTitle = "QT Demo Upgradation Details";
    page.label.message = "QT Demo Upgradation Details";
    var html = "<b>Installation Directory :</b> " + installer.value("existingInstallationPath") + "<br/><br/>";
    log("Installation Directory : " + installer.value("existingInstallationPath"));
    html = html + "<b>QT Demo Components to be upgraded</b><ul>";
    log("Below QT Demo Components going to be upgraded :- ");
    var components = installer.components();
    var compCounter = 1;
    for (i = 0; i < components.length; ++i) {
        if (components[i].installationRequested() && components[i].name == 'com.org.product.module1') {
            log("\t " + (compCounter++) + " - " + components[i].displayName);
            html = html + "<li>" + components[i].displayName + "</li>";
        } else if (components[i].installationRequested() && components[i].name == 'com.org.product.module7') {
            log("\t " + (compCounter++) + " - " + components[i].displayName);
            html = html + "<li>" + components[i].displayName + "</li>";
        } else if (components[i].installationRequested() && components[i].name == 'com.org.product.module4') {
            log("\t " + (compCounter++) + " - " + components[i].displayName);
            html = html + "<li>" + components[i].displayName + "</li>";
        } else if (components[i].installationRequested() && components[i].name == 'com.org.product.module5') {
            log("\t " + (compCounter++) + " - " + components[i].displayName);
            html = html + "<li>" + components[i].displayName + "</li>";
        } else if (components[i].installationRequested()) {
            log("\t " + (compCounter++) + " - " + components[i].displayName);
            // html = html + "<li>" + components[i].displayName + "</li>";
        }
    }
    html = html + "</ul>";
    page.installationDescription.html = html;
}

function populateInstallerInfo() {
    log("Inside Controller populateInstallerInfo()");
    //ProductVersion format in config.xml => major.minor.patch|build|branch|other
    var data = installer.value("ProductVersion");
    if (data) {
        var parts = data.split("\|");
        if (parts.length > 1) {
            var versionParts = parts[0].split("\.");
            if (versionParts.length > 2) {
                installer.setValue("QTDemoInstallerMajorVersion", versionParts[0]);
                installer.setValue("QTDemoInstallerMinorVersion", versionParts[1]);
                installer.setValue("QTDemoInstallerPatchVersion", versionParts[2]);
            }
            installer.setValue("ProductInstallerVersion", parts[0]);
        }
        installer.setValue("QTDemoInstallerBuild", parts[1]);
        installer.setValue("QTDemoInstallerBranch", parts[2]);
    }
}

function populateCommandLineArguments() {
    log("Inside populateCommandLineArguments()");
    if (installer.value("logPath")) {
        if (installer.fileExists(installer.value("logPath"))) {
            logPath = installer.value("logPath");
            log("QT Demo Installation log path : " + logPath + " provided through command line option <logPath>");
            log("Logging file updated : " + logPath + "/" + logFile);
        } else {
            log("Provided QT Demo Installation log path : " + installer.value("logPath") + " through command line option <logPath> does not exists. Using default log path : " + logPath);
        }
    } else {
        log("QT Demo Installation log path not provided through command line option <logPath> . Using default log path : " + logPath);
    }
    installer.setValue("logPath", logPath);
    installer.setValue("logFile", logFile);
    showCommandLineArguments();
    if (installer.value("silent") == 'true') {
        isSilent = true;
        log("Inside Controller(), Silent mode enabled through command line option <silent>");
    } else {
        log("Inside Controller(), Silent mode disabled");
    }

    if (installer.value("upgrade") == 'true') {
        isUpgrade = true;
        log("QT Demo Upgrade mode enabled through command line option <upgrade>");
    } else if (installer.value("uninstall") == 'true') {
        isUninstall = true;
        log("QT Demo Uninstall mode enabled through command line option <uninstall>");
    } else if (installer.value("delegatedUninstall") == 'true') {
        delegatedUninstall = true;
        log("QT Demo Delegated Uninstall mode enabled through command line option <delegatedUninstall>");
    }
    if (installer.value("installationPath")) {
        installationPath = installer.value("installationPath");
        log("QT Demo Installation path : " + installationPath + " provided through command line option <installationPath>");
    }
    if (installer.value("installModule4")) {
        installModule4 = installer.value("installModule4");
        log("QT Demo Module4 component selected/unselected (" + installModule4 + ") for Installation through command line option <installModule4>");
    }
    if (installer.value("installModule5")) {
        installModule5 = installer.value("installModule5");
        log("QT Demo Module5 component selected/unselected (" + installModule5 + ") for Installation through command line option <installModule5>");
    }
    if (installer.value("installModule1")) {
        installModule1 = installer.value("installModule1");
        log("QT Demo Module1 component selected/unselected (" + installModule1 + ") for Installation through command line option <installModule1>");
    }
    if (installer.value("module7Port")) {
        module7Port = installer.value("module7Port");
        log("QT Demo Module7 port value : " + module7Port + " provided through command line option <module7Port>");
    }
    if (installer.value("module1Port")) {
        module1Port = installer.value("module1Port");
        log("QT Demo Module1 port value : " + module1Port + " provided through command line option <Module1Port>");
    }
    if (installer.value("module4Port")) {
        module4Port = installer.value("module4Port");
        log("QT Demo Module4 port value : " + module4Port + " provided through command line option <Module4Port>");
    }
    if (installer.value("module5Port")) {
        module5Port = installer.value("module5Port");
        log("QT Demo Module5 port value : " + module5Port + " provided through command line option <Module5Port>");
    }
}

function showCommandLineArguments() {
    log('--------------- : Command line options for QT Demo installer : ---------------');
    log('OPTION : silent\t\t Values : true, false\t\t Type : Optional\t\t Default : false');
    log('OPTION : upgrade\t\t Values : true, false\t\t Type : Optional\t\t Default : false');
    log('OPTION : uninstall\t\t Values : true, false\t\t Type : Optional\t\t Default : false');
    log('OPTION : delegatedUninstall\t Values : true, false\t\t Type : Optional\t\t Default : false');
    log('OPTION : installationPath\t Values : <TargetDir>\t\t Type : Optional\t\t Default : /usr/local/QTDemoInstaller');
    log('OPTION : installModule4\t\t Values : true, false\t\t Type : Optional\t\t Default : true');
    log('OPTION : installModule5\t\t Values : true, false\t\t Type : Optional\t\t Default : true');
    log('OPTION : installModule1\t\t Values : true, false\t\t Type : Optional\t\t Default : true');
    log('OPTION : module1Port\t\t\t Values : <Module1Port>\t\t Type : Optional\t\t Default : 1234');
    log('OPTION : module7Port\t\t\t Values : <Module7Port>\t Type : Optional\t\t Default : 2345');
    log('OPTION : module4Port\t\t Values : <Module4Port>\t\t Type : Optional\t\t Default : 3456');
    log('OPTION : module5Port\t\t Values : <Module5Port>\t\t Type : Optional\t\t Default : 4567');
    log('OPTION : logPath\t\t Values : <LogDir>\t\t Type : Optional\t\t Default : <CurrentDir>');
}

function log(msg) {
    console.log(msg);
    installer.execute("/bin/sh", new Array("-c", "echo '" + msg + "' >> " + logPath + "/" + logFile));
    if (false && installer.isUninstaller() && _showInfoDialogClosed == QMessageBox.Ok) {
        _showInfoDialogClosed = showInfoDialog(msg);
    }
}

