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

var versionKey = "test.product.version";
var osKey = "test.product.plateform";
var buildKey = "test.product.build";
var installationPathKey = "test.product.path";
var version, release, path;
var installationFound = false;
var installationFolder = "/TestProduct";
var systemConfigFilePath = "/Commons/conf/DO_NOT_DELETE";
var maintenanceTool = "TestProductMaintenanceTool";
var requiredMinDiskSpace = 9; //In GB
var availableDiskSpace = 0; //In GB
var selectedPath;
var uninstallationCalled = false;
var _showInfoDialogClosed;
var _leaveAbortInstallationPageConnected = false;
var _onLeftAbortInstallationPageCalled = false
var installerInUpgradationMode = false;
var _isInterrupted = false;
var autoClickDelay = 500;
var logFile = "productInstallation.log";

// Command line options for silent installation
var isSilent = false;                       // Optional (true) default : false
var isUpgrade = false;                      // Optional (true) default : false
var isUninstall = false;                    // Optional (true) default : false
var delegatedUninstall = false;             // Optional (true) default : false
var installationPath;                       // Optional (<TargetDir>) default : /usr/local/TestProduct
var installManager;                         // Optional (true, false) default : true
var installMonitor;                         // Optional (true, false) default : true
var installDB;                              // Optional (true, false) default : true
var dbPort;                                 // Optional (<DBPort>) default : 2089
var dbPath;                                 // Optional (<TargetDBPath>) default : <InstallationPath>/DB
var smPort;                                 // Optional (<ServiceManagerPort>) default : 2069
var managerPort;                            // Optional (<ManagerPort>) default : 2029
var monitorPort;                            // Optional (<MonitorPort>) default : 2039
var logPath;                                // Optional (<LogDir>) default : <CurrentDir>

//ProductVersion format in config.xml => major.minor.patch|build|branch|other

function Controller() {
    logPath = installer.execute("pwd")[0].replace(/\r?\n|\r/g, "");
    installer.setValue("VERSION", "@ProductVersion@");
    installer.setValue("DATE", new Date());
    execute("echo 'Log file initialized' > " + logPath + "/" + logFile);
    log("Logging file : " + logPath + "/" + logFile);
    populateCommandLineArguments();
    log("Going to install Test Product version : " + installer.value("InstallerVersion"));
    log("Inside Test Product Controller()");
    _showInfoDialogClosed = QMessageBox.Ok;
    populateInstallerInfo();
    installer.setValue("systemConfigFilePath", findInstallationHomeFolder(installer.value("TargetDir")) + systemConfigFilePath);
    if (execute("rpm -qa |grep -w 'TestProduct' > /dev/null")[1] == 0) {
        var _path = execute("rpm -q --queryformat '%{instprefixes}\n' TestProduct")[0];
        installer.setValue("systemConfigFilePath", findInstallationHomeFolder(_path) + systemConfigFilePath);
    }
    log("Controller() systemConfigFilePath : " + installer.value("systemConfigFilePath"));
    installer.setValue("versionKey", versionKey);
    installer.setValue("buildKey", buildKey);
    installer.setValue("osKey", osKey);
    installer.setValue("installationPathKey", installationPathKey);
    installer.setValue("installationFolder", installationFolder);
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

    // Reference : http://doc.qt.io/qtinstallerframework/noninteractive.html
    // Uncomment below line to suppress warning for selecting non-empty directory for installation target
    installer.setMessageBoxAutomaticAnswer("OverwriteTargetDirectory", QMessageBox.Yes);
}

Controller.prototype.IntroductionPageCallback = function () {
    log("Inside Controller.IntroductionPageCallback()");
    var widget = gui.currentPageWidget();
    if (widget != null) {
        if (installer.isInstaller()) {
            widget.title = "Setup - Test Product";
            widget.MessageLabel.setText("Welcome to the Test Product Setup Wizard. The setup wizard will install Test Product " + installer.value("InstallerVersion") + " on your computer. Click Next to continue or Quit to exit the setup wizard.");
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
        html += "Aborting current Test Product installation";
        page.abortDetails.html = html;
        skipAllSteps();
    } else if (installer.value("_installationFound")) {

        if (isSilent && !isUpgrade && !isUninstall) {
            log("Other Test Product installation found and no option (Upgrade/Uninstall) provided in silent mode. Interrupting installation.");
            gui.cancelButtonClicked();
            return;
        }
        page.uninstall.setVisible(true);

        if (fileExists(systemConfigFilePath)) {
            if (release < installer.value("InstallerBuild")) {
                // Case 1 : If Conf file  present and lower version Test Product installed
                var html = "Test Product already installed.<br/><br/>";
                html += "<b>Installation Directory :</b> " + findInstallationHomeFolder(path) + "<br/>";
                html += "<b>Installer Version :</b> " + installer.value("InstallerVersion") + "<br/>";
                html += "<b>Installer Release :</b> " + installer.value("InstallerBuild") + "<br/><br/><br/>";
                html += "A lower version of Test Product " + version + "-" + release + " is installed<br/><br/>";
                html += "Select appropriate action to be performed";
                page.upgrade.setVisible(true);
                page.abortDetails.html = html;
                if (isUpgrade) {
                    page.upgrade.setChecked(true);
                }
            } else {
                // Case 3 : If Conf file present but installed version is same or higher
                var html = "Test Product already installed.<br/><br/>";
                html += "<b>Installation Directory :</b> " + findInstallationHomeFolder(path) + "<br/>";
                html += "<b>Installer Version :</b> " + installer.value("InstallerVersion") + "<br/>";
                html += "<b>Installer Release :</b> " + installer.value("InstallerBuild") + "<br/><br/><br/>";
                html += "A higher or same version of Test Product " + version + "-" + release + " is already installed<br/><br/>";
                html += "To install an older or same version of Test Product, uninstall the existing version first";
                page.upgrade.setVisible(false);
                page.abortDetails.html = html;
            }
        } else {
            // Case 2 : If Conf file not present
            var html = "Test Product already installed.<br/><br/>";
            html += "<b>Installation Directory :</b> " + findInstallationHomeFolder(path) + "<br/>";
            html += "<b>Installed Version :</b> " + version + "<br/>";
            html += "<b>Installed Release :</b> " + release + "<br/><br/><br/>";
            html += "Test Product installation found but either Test Product is not installed properly or some files got deleted.<br/><br/>";
            html += "Please reinstall the Test Product";
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
            if (QMessageBox.critical("product-installer-critical", "Installer", 'Upgrade option provided through command line options. But Upgarde operation not supported. Interrupting installation.', QMessageBox.Ok) == QMessageBox.Ok) {
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
            log("User selected Uninstallation for Test Product");
            // skipAllSteps();
            // installer.setUninstaller();
            delegatedUninstall = true;
            installerInUpgradationMode = false;
            installer.setValue("installerInUpgradationMode", "false");
            launchMaintenanceTool();
        }
        if (widget.upgrade.checked) {
            log("User selected Upgradation for Test Product");
            installerInUpgradationMode = true;
            delegatedUninstall = false;
            installer.setValue("installerInUpgradationMode", "true");
            installer.setValue("TargetDir", installer.value("existingInstallationPath"));

            var components = installer.components();
            for (i = 0; i < components.length; ++i) {
                var installationRequested = getConfProperty(components[i].name);
                installer.setValue("installationRequested_" + components[i].name, installationRequested ? installationRequested : "false");
            }

            if (installerInUpgradationMode) {
                var result = installer.executeDetached("/bin/sh", new Array("-c", "rm -Rf " + findInstallationHomeFolder(path) + maintenanceTool));
                result = installer.executeDetached("/bin/sh", new Array("-c", "rm -Rf " + findInstallationHomeFolder(path) + "/" + maintenanceTool + ".ini"));
                result = installer.executeDetached("/bin/sh", new Array("-c", "rm -Rf " + findInstallationHomeFolder(path) + "/" + maintenanceTool + ".dat"));
                result = installer.executeDetached("/bin/sh", new Array("-c", "rm -Rf /tmp/" + maintenanceTool + "*.lock"));
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
        } else if (installer.value("insufficientFileAccessPermissions") === "true") {
            widget.WarningLabel.setText("Insufficient File Access Permissions. Installation directory should have a minimum of r-xr-xr-x permissions.\n\nPlease specify a valid installation directory.");
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
        if (selectedPath.endsWith(installationFolder)) {
            selectedPath = selectedPath.substr(0, selectedPath.lastIndexOf(installationFolder));
        }
        if (!installer.fileExists(selectedPath)) {
            installer.setValue("invalidTargetPath", "true");
            installer.setValue("insufficientDiskSpace", "false");
            installer.setValue("insufficientFileAccessPermissions", "false");

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
            installer.setValue("TargetDir", findInstallationHomeFolder(selectedPath));
            installer.setValue("systemConfigFilePath", findInstallationHomeFolder(selectedPath) + systemConfigFilePath);
        }

        // Validate minimum available space in selected path
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

        // Validate file access permissions on selected path
        if (hasInsufficientFileAccessPermissions(selectedPath)) {
            installer.setValue("insufficientFileAccessPermissions", "true");
            if (isSilent) {
                log("Insufficient File Access Permissions on provided target directory in silent mode. Interrupting installation.");
                gui.cancelButtonClicked();
            } else {
                gui.clickButton(buttons.BackButton, autoClickDelay);
            }
        } else {
            installer.setValue("insufficientFileAccessPermissions", "false");
        }
    }
}

Controller.prototype.ComponentSelectionPageCallback = function () {
    log("Inside Controller.prototype.ComponentSelectionPageCallback()");
    var components = installer.components();
    var rootComp = null;
    for (i = 0; i < components.length; ++i) {
        if (components[i].installationRequested() && components[i].name == 'test.product.db') {
            if (installer.removeWizardPage(components[i], "DBConfigurationPage")) {
                log("WizardPage DBConfigurationPage removed.");
            }
        } else if (components[i].installationRequested() && components[i].name == 'test.product.sm') {
            if (installer.removeWizardPage(components[i], "ServiceManagerConfigurationPage")) {
                log("WizardPage ServiceManagerConfigurationPage removed.");
            }
        } else if (components[i].installationRequested() && components[i].name == 'test.product.manager') {
            if (installer.removeWizardPage(components[i], "ManagerConfigurationPage")) {
                log("WizardPage ManagerConfigurationPage removed.");
            }
        } else if (components[i].installationRequested() && components[i].name == 'test.product.monitor') {
            if (installer.removeWizardPage(components[i], "MonitorConfigurationPage")) {
                log("WizardPage MonitorConfigurationPage removed.");
            }
        } else if (components[i].name == 'test.product') {
            if (installer.removeWizardPage(components[i], "InstallationDetailsPage")) {
                log("WizardPage InstallationDetailsPage removed.");
            }
        }
    }
    var widget = gui.currentPageWidget();
    if (installDB && installDB == 'true') {
        widget.selectComponent('test.product.db');
    }
    if (installDB && installDB == 'false') {
        widget.deselectComponent('test.product.db');
    }
    if (installManager && installManager == 'true') {
        widget.selectComponent('test.product.manager');
    }
    if (installManager && installManager == 'false') {
        widget.deselectComponent('test.product.manager');
    }
    if (installMonitor && installMonitor == 'true') {
        widget.selectComponent('test.product.monitor');
    }
    if (installMonitor && installMonitor == 'false') {
        widget.deselectComponent('test.product.monitor');
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

        if (components[i].installationRequested() && components[i].name == 'test.product.db') {
            if (!installer.addWizardPage(components[i], "DBConfigurationPage", QInstaller.ReadyForInstallation)) {
                log("Could not load DBConfigurationPage. Using default port value.");
            }
        } else if (components[i].installationRequested() && components[i].name == 'test.product.sm') {
            if (!installer.addWizardPage(components[i], "ServiceManagerConfigurationPage", QInstaller.ReadyForInstallation)) {
                log("Could not load ServiceManagerConfigurationPage. Using default port value.");
            }
        } else if (components[i].installationRequested() && components[i].name == 'test.product.manager') {
            if (!installer.addWizardPage(components[i], "ManagerConfigurationPage", QInstaller.ReadyForInstallation)) {
                log("Could not load ManagerConfigurationPage. Using default port value.");
            }
        } else if (components[i].installationRequested() && components[i].name == 'test.product.monitor') {
            if (!installer.addWizardPage(components[i], "MonitorConfigurationPage", QInstaller.ReadyForInstallation)) {
                log("Could not load MonitorConfigurationPage. Using default port value.");
            }
        } else if (components[i].name == 'test.product') {
            installer.addWizardPage(components[i], "InstallationDetailsPage", QInstaller.ReadyForInstallation);
        }
    }
}

Controller.prototype.LicenseAgreementPageCallback = function () {
    log("Inside Controller.LicenseAgreementPageCallback()");
    var widget = gui.currentPageWidget();
    if (!widget) {
        log("Controller.prototype.LicenseAgreementPageCallback() :: Page widget undefined");
        return;
    }
    // logObjectDepthInfo(widget);
    widget.title = "End-User License Agreement";
    widget.subTitle = "Please read the following license agreement carefully";

    widget.findChild("AcceptLicenseLabel").setText("I accept the terms in the license agreement");
    widget.findChild("RejectLicenseLabel").setText("I do not accept the terms in the license agreement");
    // Rollback changes of Issue OOT-5806 (as we need to preserve installer default behaviour)
    // widget.findChild("RejectLicenseLabel").setVisible(false);
    // widget.findChild("RejectLicenseRadioButton").setVisible(false);
    if (isSilent) {
        widget.findChild("AcceptLicenseRadioButton").checked = true;
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

var smPortInputConnected = false;

Controller.prototype.DynamicServiceManagerConfigurationPageCallback = function () {
    log("Inside Controller.prototype.DynamicServiceManagerConfigurationPageCallback()");
    var component = gui.pageWidgetByObjectName("DynamicServiceManagerConfigurationPage");
    if (!smPortInputConnected) {
        component.smPort.cursorPositionChanged.connect(component, onCursorChangeSMPort);
        log("smPort Connected to action onCursorChangeSMPort");
        smPortInputConnected = true;
    }
    if (smPort) {
        component.smPort.setText(smPort);
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

var dbPathButtonConnected = false;

Controller.prototype.DynamicDBConfigurationPageCallback = function () {
    log("Inside Controller.prototype.DynamicDBConfigurationPageCallback()");
    var component = gui.pageWidgetByObjectName("DynamicDBConfigurationPage");
    // dbPathButton, dbPath, dbPort
    if (!dbPathButtonConnected) {
        component.dbPath.text = findInstallationHomeFolder(installer.value("TargetDir")) + "/DB";
        component.defaultDBLocationCheckBox.stateChanged.connect(component, onClickDefaultDBLocationCheckBox);
        component.dbPathButton.clicked.connect(this, onClickBrowseDBPath);
        component.dbPort.cursorPositionChanged.connect(component, onCursorChangeDBPort);
        log("dbPathButton Connected to action onClickBrowseDBPath");
        dbPathButtonConnected = true;
    }
    if (dbPort) {
        component.dbPort.setText(dbPort);
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
    }
}

var managerPortInputConnected = false;

Controller.prototype.DynamicManagerConfigurationPageCallback = function () {
    log("Inside Controller.prototype.DynamicManagerConfigurationPageCallback()");
    var component = gui.pageWidgetByObjectName("DynamicManagerConfigurationPage");
    if (!managerPortInputConnected) {
        component.managerPort.cursorPositionChanged.connect(component, onCursorChangeManagerPort);
        log("managerPort Connected to action onCursorChangeManagerPort");
        managerPortInputConnected = true;
    }
    if (managerPort) {
        component.managerPort.setText(managerPort);
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton);
    }
}

var monitorPortInputConnected = false;

Controller.prototype.DynamicMonitorConfigurationPageCallback = function () {
    log("Inside Controller.prototype.DynamicMonitorConfigurationPageCallback()");
    var component = gui.pageWidgetByObjectName("DynamicMonitorConfigurationPage");
    if (!monitorPortInputConnected) {
        component.monitorPort.cursorPositionChanged.connect(component, onCursorChangeMonitorPort);
        log("monitorPort Connected to action onCursorChangeMonitorPort");
        monitorPortInputConnected = true;
    }
    if (monitorPort) {
        component.monitorPort.setText(monitorPort);
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
        installer.setValue("uninstallationRequested_test.product", "true");
        installer.setValue("uninstallationRequested_test.product.sm", "true");
        installer.setValue("uninstallationRequested_test.product.manager", "true");
        installer.setValue("uninstallationRequested_test.product.monitor", "true");
        installer.setValue("uninstallationRequested_test.product.db", "true");
        if (delegatedUninstall) {
            gui.clickButton(buttons.NextButton, autoClickDelay);
            return;
        }
    }
    if (installerInUpgradationMode) {
        var widget = gui.currentPageWidget();
        if (widget != null) {
            widget.title = "Ready to upgrade";
            widget.MessageLabel.setText("Setup is now ready to begin upgrading Test Product on your computer. Do not interrupt process, as interruption may corrupt existing installation.");
        }
    }
    if (installer.value("portNotAvailable") == "true") {
        log("Any port is not available, so unable to continue with given details.");
        gui.clickButton(buttons.BackButton, autoClickDelay);
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
        widget.title = "Completing the Test Product Wizard";
        if (installer.isInstaller() && installer.value('installationRequested_test.product.monitor') == 'true') {
            // var html = "System reboot required for proper installation. On click of Finish, system will be rebooted automatically.<br><br>";
            var html = "Click Finish to exit the Test Product Wizard.";
            widget.MessageLabel.setText(html);
        }
    }
    if (isSilent) {
        gui.clickButton(buttons.FinishButton, autoClickDelay);
    }
}

function onLeftFinishedPage() {
    log("onLeftFinishedPage called");
    if (installer.isInstaller() && installer.value('installationRequested_test.product.monitor') == 'true') {
        // log("Going to restart system");
        // installer.executeDetached("shutdown", "-r", "+1", "System will restart in 1 minute. Please save your work.");
    }
}

function checkOldInstallation() {
    log("Inside Controller checkOldInstallation()");
    log("Looking if an Test Product installation already exists on this machine ....");

    if (installationFound = execute("rpm -qa |grep -w 'TestProduct' > /dev/null")[1] == 0) {
        log("Operating System : " + (execute("rpm -qa \*-release | head -1")[0]));
        log("Installed Version : " + (version = execute("rpm -q --queryformat '%{version}\n' TestProduct")[0]));
        log("Installed Release : " + (release = execute("rpm -q --queryformat '%{release}\n' TestProduct")[0]));
        log("Test Product Installation Path : " + (path = execute("rpm -q --queryformat '%{instprefixes}\n' TestProduct")[0]));
        if (version || release || path) {
            log("Found an existing Test Product Installation.");
            installer.setValue("_installationFound", installationFound);
        }
        installer.setValue("existingInstallationPath", findInstallationHomeFolder(path));
        systemConfigFilePath = findInstallationHomeFolder(path) + systemConfigFilePath;
        installer.setValue("systemConfigFilePath", systemConfigFilePath);
        //log("Using flag _installationFound Test Product Component will launch AbortInstallationPage");
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
    var line = installer.execute("grep", new Array(key + "=", systemConfigFilePath))[0];
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

function hasInsufficientFileAccessPermissions(folderPath) {
    var folderHasInsufficientFileAccessPermissions = false;
    var resultArr = installer.execute("/bin/sh", new Array("-c", "namei -m " + folderPath));
    if (resultArr && resultArr.length > 1 && resultArr[1] == 0) {
        var tmpPermissionsTokens = resultArr[0].split(" ");
        for (i = 0; i < tmpPermissionsTokens.length; ++i) {
            if (i > 0 && (i % 2) == 0) {
                var token = tmpPermissionsTokens[i];
                var rCount = (token.match(/r/g) || []).length;
                var wCount = (token.match(/w/g) || []).length;
                var xCount = (token.match(/x/g) || []).length;
                if (rCount < 3 || xCount < 3) {
                    log("Path " + folderPath + " has insufficient file access permissions.");
                    folderHasInsufficientFileAccessPermissions = true;
                    break;
                }
            }
        }
    }
    if (!folderHasInsufficientFileAccessPermissions) {
        log("Path " + folderPath + " has sufficient file access permissions.");
    }
    return folderHasInsufficientFileAccessPermissions;
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
        if (components[i].name == 'test.product') {
            installer.addWizardPage(components[i], "InstallationDetailsPage", QInstaller.ReadyForInstallation);
            log("WizardPage InstallationDetailsPage added.");
            break;
        }
    }

    if (!_leaveAbortInstallationPageConnected) {
        _leaveAbortInstallationPageConnected = true;
        log("Connecting onLeftAbortInstallationPage on entered InstallationDetailsPage");
        var page = gui.pageByObjectName("DynamicInstallationDetailsPage");
        if (page) {
            page.entered.connect(onLeftAbortInstallationPage);
        }
    }
}

function launchMaintenanceTool() {
    log("Launching Test Product Maintenance Tool");
    //Uninstall Test Product
    if (installer.fileExists(findInstallationHomeFolder(path) + "/" + maintenanceTool)) {
        if (installer.executeDetached("/bin/sh", new Array("-c", "sleep 0.2 && rm -f /tmp/TestProductMaintenanceTool*.lock && " + findInstallationHomeFolder(path) + "/" + maintenanceTool + " delegatedUninstall=true silent=" + isSilent))) {
            log("Test Product Maintenance Tool launched, exiting from installation wizard");
            // gui.reject();
            gui.rejectWithoutPrompt();
        }
    } else {
        log("Uninstalling Test Product");
        if (!isSilent && QMessageBox.warning("product-installer-warning", "Installer", "Test Product was installed through Command-Line installer and you are trying to remove it using GUI installer. Uninstallation progress will not be visible but will run in the background. Do you wish to continue?", QMessageBox.Yes | QMessageBox.No) == QMessageBox.No) {
            log("Test Product uninstallation aborted by user, exiting from installation wizard")
            gui.rejectWithoutPrompt();
            return;
        }
        execute("export PRODUCT_INSTALLPATH=" + findInstallationPath(path) + "; rpm -e TestProduct | tee -a " + logPath + "/" + logFile);
        execute("rm -rf " + findInstallationHomeFolder(path));
        if (!isSilent) {
            QMessageBox.information("product-installer-info", "Installer", "Test Product removed successfully", QMessageBox.Ok);
        }
        log("Test Product uninstalled successfully, exiting from installation wizard")
        gui.rejectWithoutPrompt();
    }
}

function showInfoDialog(msg) {
    return QMessageBox.information("product-installer-info", "Installer", msg, QMessageBox.Ok);
}

function askQuestionDialog(msg) {
    // Ref : http://doc.qt.io/qt-5/qmessagebox-obsolete.html
    // QMessageBox will return clicked button int value
    // Default buttons : NoButton, Ok, Cancel, Yes, No, Abort, Retry, Ignore, YesAll, NoAll
    return QMessageBox.question("product-installer-question", "Installer", msg, QMessageBox.Ok | QMessageBox.Cancel);
}

function showWarningDialog(msg) {
    return QMessageBox.warning("product-installer-warning", "Installer", msg, QMessageBox.Ok);
}

function showCriticalDialog(msg) {
    return QMessageBox.critical("product-installer-critical", "Installer", msg, QMessageBox.Ok);
}

function onChangePackageManagerCoreType() {
    log("Inside onChangePackageManagerCoreType()");
    log("Is Installer: " + installer.isInstaller());
    log("Is Updater: " + installer.isUpdater());
    log("Is Uninstaller: " + installer.isUninstaller());
    log("Is Package Manager: " + installer.isPackageManager());
}

function killServiceByPID(serviceName) {
    //kill -SIGTERM  $(ps -ax | grep TestProductServiceManager | head -1 | awk -F' ' '{print $1}')
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
        uninstallDB();
        uninstallServiceManager();
        uninstallManager();
        uninstallMonitor();
        uninstall();

        onUninstallationFinished(true);
        uninstallationCalled = true;
    }
}

function onUninstallationStarted() {
    log("Inside onUninstallationStarted()");

    if (installer.value("installerInUpgradationMode") == "true") {
        return;
    }
    if (installer.value("uninstallationRequested_test.product.db") == "true") {
        // uninstallDB();
    }
    if (installer.value("uninstallationRequested_test.product.sm") == "true") {
        // uninstallServiceManager();
    }
    if (installer.value("uninstallationRequested_test.product.manager") == "true") {
        // uninstallManager();
    }
    if (installer.value("uninstallationRequested_test.product.monitor") == "true") {
        // uninstallMonitor();
    }
}

function uninstall() {
    log("Inside uninstall()");
    var homeDir = installer.value("HomeDir");
    installer.execute("rm", new Array("-f", systemConfigFilePath));
    installer.execute("rm", new Array("-f", homeDir + "/.flexlmrc"));
}

function uninstallDB() {
    log("Inside uninstallDB()");
}

function uninstallServiceManager() {
    log("Inside uninstallServiceManager()");
    var destDir = installer.value("TargetDir") + "/ServiceManager";
}

function uninstallManager() {
    log("Inside uninstallManager()");
    var destDir = installer.value("TargetDir") + "/Manager";
}

function uninstallMonitor() {
    log("Inside uninstallMonitor()");
    var destDir = installer.value("TargetDir") + "/Monitor";
}

function onUninstallationFinished(isInterrupted) {
    log("Inside onUninstallationFinished()");

    if (installer.value("installerInUpgradationMode") == "true") {
        installer.executeDetached("service TestProductServiceManager start");
        if (isSilent) {
            gui.clickButton(buttons.NextButton, autoClickDelay);
            gui.clickButton(buttons.FinishButton, autoClickDelay);
        }
        return;
    }

    var destDir = installer.value("TargetDir");

    if (isInterrupted || installer.value("uninstallationRequested_test.product.db") == "true") {
        installer.execute("rm", new Array("-Rf", destDir + "/DB"));
    }
    if (isInterrupted || installer.value("uninstallationRequested_test.product.sm") == "true") {
        installer.execute("rm", new Array("-Rf", destDir + "/ServiceManager"));
    }
    if (isInterrupted || installer.value("uninstallationRequested_test.product.manager") == "true") {
        installer.execute("rm", new Array("-Rf", destDir + "/Manager"));
    }
    if (isInterrupted || installer.value("uninstallationRequested_test.product.monitor") == "true") {
        installer.execute("rm", new Array("-Rf", destDir + "/Monitor"));
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
        installer.executeDetached("service TestProductServiceManager start");
        installer.execute("cp", targetDir + "InstallationLog.txt", installationPath + "InstallationLog.txt");

        if (isSilent) {
            gui.clickButton(buttons.NextButton, autoClickDelay);
            gui.clickButton(buttons.FinishButton, autoClickDelay);
        }
        return;
    }

    var targetDir = installer.value("TargetDir");
    if (installer.isInstaller() && installer.value("installationRequested_test.product.sm") == "true") {
        installwkHTMLtoPDF();
        manageInstallationFolders();
        // log("Starting Test Product Service Manager");
        // log("Execute java -jar " + targetDir + "/ServiceManager/lib/Config.jar startOSMService " + targetDir + "/ServiceManager ");
        // installer.executeDetached("java", new Array("-jar", targetDir + "/ServiceManager/lib/Config.jar", "startOSMService", targetDir + "/ServiceManager"));
        // log("Test Product Service Manager started");
    }
    if (isSilent) {
        gui.clickButton(buttons.NextButton, autoClickDelay);
        gui.clickButton(buttons.FinishButton, autoClickDelay);
    }
}

function validateUser() {
    log("Inside Controller validateUser()");
    var userId = installer.execute("id", "-u")[0].replace(/\r?\n|\r/g, "");
    if (userId + "" != "0") {
        log("Installer must be run as root. Aborting installation");
        installer.setValue("_nonRootUser", "true");
        // log("Using flag _nonRootUser Test Product Component will launch AbortInstallationPage");
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
    html = html + "<b>Test Product Components to be installed</b><ul>";
    log("Below Test Product Components going to be installed :- ");
    var components = installer.components();
    var compCounter = 1;
    var portNotAvailable = false;
    for (i = 0; i < components.length; ++i) {
        if (components[i].installationRequested() && components[i].name == 'test.product.db') {
            var compPage = gui.pageWidgetByObjectName("DynamicDBConfigurationPage");
            if (!compPage) {
                installer.setValue("dbPort", "0000");
            } else if (compPage.dbPort.text) {
                installer.setValue("dbPort", compPage.dbPort.text.trim());
            } else {
                installer.setValue("dbPort", compPage.dbPort.placeholderText);
            }
            installer.setValue("dbPath", compPage.dbPath.text.trim());
            if (portAvailable(installer.value("dbPort"))) {
                log("\t " + (compCounter++) + " - " + components[i].displayName + " : on port " + installer.value("dbPort", "0000"));
                html = html + "<li>" + components[i].displayName + " on port : " + installer.value("dbPort", "0000") + "</li>";
            } else {
                portNotAvailable = true;
                log("\t " + (compCounter++) + " - " + components[i].displayName + " : on port " + installer.value("dbPort", "0000") + " (Port Not Available)");
                html = html + "<li>" + components[i].displayName + " on port : " + installer.value("dbPort", "0000") + " (Port Not Available)" + "</li>";
            }
            log("\t " + (compCounter++) + " - " + components[i].displayName + " : on path " + installer.value("dbPath"));
            html = html + "<li>" + components[i].displayName + " on path : " + installer.value("dbPath") + "</li>";
        } else if (components[i].installationRequested() && components[i].name == 'test.product.sm') {
            var compPage = gui.pageWidgetByObjectName("DynamicServiceManagerConfigurationPage");
            if (!compPage) {
                installer.setValue("smPort", "0000");
            } else if (compPage.smPort.text) {
                installer.setValue("smPort", compPage.smPort.text.trim());
            } else {
                installer.setValue("smPort", compPage.smPort.placeholderText);
            }
            if (portAvailable(installer.value("smPort"))) {
                log("\t " + (compCounter++) + " - " + components[i].displayName + " : on port " + installer.value("smPort", "0000"));
                html = html + "<li>" + components[i].displayName + " on port : " + installer.value("smPort", "0000") + "</li>";
            } else {
                portNotAvailable = true;
                log("\t " + (compCounter++) + " - " + components[i].displayName + " : on port " + installer.value("smPort", "0000") + " (Port Not Available)");
                html = html + "<li>" + components[i].displayName + " on port : " + installer.value("smPort", "0000") + " (Port Not Available)" + "</li>";
            }
        } else if (components[i].installationRequested() && components[i].name == 'test.product.manager') {
            var compPage = gui.pageWidgetByObjectName("DynamicManagerConfigurationPage");
            if (!compPage) {
                installer.setValue("managerPort", "0000");
            } else if (compPage.managerPort.text) {
                installer.setValue("managerPort", compPage.managerPort.text.trim());
            } else {
                installer.setValue("managerPort", compPage.managerPort.placeholderText);
            }
            if (portAvailable(installer.value("managerPort"))) {
                log("\t " + (compCounter++) + " - " + components[i].displayName + " : on port " + installer.value("managerPort", "0000"));
                html = html + "<li>" + components[i].displayName + " on port : " + installer.value("managerPort", "0000") + "</li>";
            } else {
                portNotAvailable = true;
                log("\t " + (compCounter++) + " - " + components[i].displayName + " : on port " + installer.value("managerPort", "0000") + " (Port Not Available)");
                html = html + "<li>" + components[i].displayName + " on port : " + installer.value("managerPort", "0000") + " (Port Not Available)" + "</li>";
            }
        } else if (components[i].installationRequested() && components[i].name == 'test.product.monitor') {
            var compPage = gui.pageWidgetByObjectName("DynamicMonitorConfigurationPage");
            if (!compPage) {
                installer.setValue("monitorPort", "0000");
            } else if (compPage.monitorPort.text) {
                installer.setValue("monitorPort", compPage.monitorPort.text.trim());
            } else {
                installer.setValue("monitorPort", compPage.monitorPort.placeholderText);
            }
            if (portAvailable(installer.value("monitorPort"))) {
                log("\t " + (compCounter++) + " - " + components[i].displayName + " : on port " + installer.value("monitorPort", "0000"));
                html = html + "<li>" + components[i].displayName + " on port : " + installer.value("monitorPort", "0000") + "</li>";
            } else {
                portNotAvailable = true;
                log("\t " + (compCounter++) + " - " + components[i].displayName + " : on port " + installer.value("monitorPort", "0000") + " (Port Not Available)");
                html = html + "<li>" + components[i].displayName + " on port : " + installer.value("monitorPort", "0000") + " (Port Not Available)" + "</li>";
            }
        } else if (components[i].installationRequested()) {
            log("\t " + (compCounter++) + " - " + components[i].displayName);
            // html = html + "<li>" + components[i].displayName + "</li>";
        }
    }
    if (portNotAvailable) {
        installer.setValue("portNotAvailable", "true");
    } else {
        installer.setValue("portNotAvailable", "false");
    }
    html = html + "</ul>";
    page.installationDescription.html = html;
}

function populateUpgradationDetails() {
    log("Inside Controller populateUpgradationDetails()");
    var page = gui.pageWidgetByObjectName("DynamicInstallationDetailsPage");
    //page.setProperty("windowTitle", "Test Product Upgradation Details");
    //page.label.setProperty("message", "Test Product Upgradation Details");
    page.windowTitle = "Test Product Upgradation Details";
    page.label.message = "Test Product Upgradation Details";
    var html = "<b>Installation Directory :</b> " + installer.value("existingInstallationPath") + "<br/><br/>";
    log("Installation Directory : " + installer.value("existingInstallationPath"));
    html = html + "<b>Test Product Components to be upgraded</b><ul>";
    log("Below Test Product Components going to be upgraded :- ");
    var components = installer.components();
    var compCounter = 1;
    for (i = 0; i < components.length; ++i) {
        if (components[i].installationRequested() && components[i].name == 'test.product.db') {
            log("\t " + (compCounter++) + " - " + components[i].displayName);
            // html = html + "<li>" + components[i].displayName + "</li>";
        } else if (components[i].installationRequested() && components[i].name == 'test.product.sm') {
            log("\t " + (compCounter++) + " - " + components[i].displayName);
            // html = html + "<li>" + components[i].displayName + "</li>";
        } else if (components[i].installationRequested() && components[i].name == 'test.product.manager') {
            log("\t " + (compCounter++) + " - " + components[i].displayName);
            html = html + "<li>" + components[i].displayName + "</li>";
        } else if (components[i].installationRequested() && components[i].name == 'test.product.monitor') {
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
                installer.setValue("InstallerMajorVersion", versionParts[0]);
                installer.setValue("InstallerMinorVersion", versionParts[1]);
                installer.setValue("InstallerPatchVersion", versionParts[2]);
            }
            installer.setValue("InstallerVersion", parts[0]);
        }
        installer.setValue("InstallerBuild", parts[1]);
        installer.setValue("InstallerBranch", parts[2]);
    }
}

function populateCommandLineArguments() {
    log("Inside populateCommandLineArguments()");
    if (installer.value("logPath")) {
        if (installer.fileExists(installer.value("logPath"))) {
            logPath = installer.value("logPath");
            log("Initializing log file");
            execute("echo 'Log file initialized' > " + logPath + "/" + logFile);
            log("Test Product Installation log path : " + logPath + " provided through command line option <logPath>");
            log("Logging file updated : " + logPath + "/" + logFile);
        } else {
            log("Provided Test Product Installation log path : " + installer.value("logPath") + " through command line option <logPath> does not exists. Using default log path : " + logPath);
        }
    } else {
        log("Test Product Installation log path not provided through command line option <logPath> . Using default log path : " + logPath);
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
        log("Test Product Upgrade mode enabled through command line option <upgrade>");
    } else if (installer.value("uninstall") == 'true') {
        isUninstall = true;
        log("Test Product Uninstall mode enabled through command line option <uninstall>");
    } else if (installer.value("delegatedUninstall") == 'true') {
        delegatedUninstall = true;
        log("Test Product Delegated Uninstall mode enabled through command line option <delegatedUninstall>");
    }
    if (installer.value("installationPath")) {
        installationPath = installer.value("installationPath");
        log("Test Product Installation path : " + installationPath + " provided through command line option <installationPath>");
    }
    if (installer.value("installManager")) {
        installManager = installer.value("installManager");
        log("Test Product Manager component selected/unselected (" + installManager + ") for Installation through command line option <installManager>");
    }
    if (installer.value("installMonitor")) {
        installMonitor = installer.value("installMonitor");
        log("Test Product Monitor component selected/unselected (" + installMonitor + ") for Installation through command line option <installMonitor>");
    }
    if (installer.value("installDB")) {
        installDB = installer.value("installDB");
        log("Test Product DB component selected/unselected (" + installDB + ") for Installation through command line option <installDB>");
    }
    if (installer.value("smPort")) {
        smPort = installer.value("smPort");
        log("Test Product Service Manager port value : " + smPort + " provided through command line option <smPort>");
    }
    if (installer.value("dbPort")) {
        dbPort = installer.value("dbPort");
        log("Test Product DB port value : " + dbPort + " provided through command line option <dbPort>");
    }
    if (installer.value("dbPath")) {
        dbPath = installer.value("dbPath");
        log("Test Product DB path value : " + dbPath + " provided through command line option <dbPath>");
    }
    if (installer.value("managerPort")) {
        managerPort = installer.value("managerPort");
        log("Test Product Manager port value : " + managerPort + " provided through command line option <managerPort>");
    }
    if (installer.value("monitorPort")) {
        monitorPort = installer.value("monitorPort");
        log("Test Product Monitor port value : " + monitorPort + " provided through command line option <monitorPort>");
    }
}

function showCommandLineArguments() {
    log('--------------- : Command line options for Test Product installer : ---------------');
    log('OPTION : silent\t\t\t Values : true, false\t\t Type : Optional\t\t Default : false');
    log('OPTION : upgrade\t\t Values : true, false\t\t Type : Optional\t\t Default : false');
    log('OPTION : uninstall\t\t Values : true, false\t\t Type : Optional\t\t Default : false');
    log('OPTION : delegatedUninstall\t Values : true, false\t\t Type : Optional\t\t Default : false');
    log('OPTION : installationPath\t Values : <TargetDir>\t\t Type : Optional\t\t Default : /usr/local/TestProduct');
    log('OPTION : installManager\t\t Values : true, false\t\t Type : Optional\t\t Default : true');
    log('OPTION : installMonitor\t\t Values : true, false\t\t Type : Optional\t\t Default : true');
    log('OPTION : installDB\t\t Values : true, false\t\t Type : Optional\t\t Default : true');
    log('OPTION : dbPort\t\t\t Values : <DBPort>\t\t Type : Optional\t\t Default : 2089');
    log('OPTION : dbPath\t\t\t Values : <TargetDBPath>\t Type : Optional\t\t Default : <InstallationPath>/DB');
    log('OPTION : smPort\t\t\t Values : <ServiceManagerPort>\t Type : Optional\t\t Default : 2069');
    log('OPTION : managerPort\t\t Values : <ManagerPort>\t\t Type : Optional\t\t Default : 2029');
    log('OPTION : monitorPort\t\t Values : <MonitorPort>\t\t Type : Optional\t\t Default : 2039');
    log('OPTION : logPath\t\t Values : <LogDir>\t\t Type : Optional\t\t Default : <CurrentDir>');
}

function log(msg) {
    console.log(msg);
    installer.execute("/bin/sh", new Array("-c", "echo '" + msg + "' >> " + logPath + "/" + logFile));
    if (false && installer.isUninstaller() && _showInfoDialogClosed == QMessageBox.Ok) {
        _showInfoDialogClosed = showInfoDialog(msg);
    }
}

function findInstallationHomeFolder(location) {
    if (location.endsWith(installationFolder)) {
        return location;
    } else {
        return location + installationFolder;
    }
}

function findInstallationPath(location) {
    var targetDir = location;
    var installationFolder = installer.value("installationFolder");
    return targetDir.substring(0, targetDir.indexOf(installationFolder) > -1 ? targetDir.indexOf(installationFolder) : targetDir.length);
}

function onClickDefaultDBLocationCheckBox(state) {
    if (state) {
        this.dbPathButton.setDisabled(true);
    } else {
        this.dbPathButton.setEnabled(true);
    }
}

function onClickBrowseDBPath(comp) {
    // dbPathButton, dbPath
    var installationPath = findInstallationHomeFolder(installer.value("TargetDir"));
    var component = gui.pageWidgetByObjectName("DynamicDBConfigurationPage");
    var newDBPath = QFileDialog.getExistingDirectory("Choose data directory for the Test Product Database.", installationPath);
    if (newDBPath) {
        component.dbPath.text = newDBPath;
    }
    log("dbPath changed : " + component.dbPath.text);
}

function onCursorChangeSMPort(oldPos, newPos) {
    // QMessageBox.information("product-installer-info", "Installer", "SM Port cusror position changed", QMessageBox.Ok);
    var portLength = this.smPort.text.trim().length;
    if (this.smPort.cursorPosition != portLength) {
        this.smPort.cursorPosition = portLength;
    }
}

function onCursorChangeManagerPort(oldPos, newPos) {
    // QMessageBox.information("product-installer-info", "Installer", "Manager Port cusror position changed", QMessageBox.Ok);
    var portLength = this.managerPort.text.trim().length;
    if (this.managerPort.cursorPosition != portLength) {
        this.managerPort.cursorPosition = portLength;
    }
}

function onCursorChangeMonitorPort(oldPos, newPos) {
    // QMessageBox.information("product-installer-info", "Installer", "Monitor Port cusror position changed", QMessageBox.Ok);
    var portLength = this.monitorPort.text.trim().length;
    if (this.monitorPort.cursorPosition != portLength) {
        this.monitorPort.cursorPosition = portLength;
    }
}

function onCursorChangeDBPort(oldPos, newPos) {
    // QMessageBox.information("product-installer-info", "Installer", "DB Port cusror position changed", QMessageBox.Ok);
    var portLength = this.dbPort.text.trim().length;
    if (this.dbPort.cursorPosition != portLength) {
        this.dbPort.cursorPosition = portLength;
    }
}

function portAvailable(port) {
    if (execute("netstat -ln | grep :" + port + " | grep 'LISTEN'  > /dev/null")[1] == 1) {
        return true;
    } else {
        return false;
    }
}

function installwkHTMLtoPDF() {
    var wkhtmltopdfPath = findInstallationHomeFolder(installer.value("TargetDir")) + "/Manager/Tools/pdfGen";
    var wkhtmltopdfPackage = "wkhtmltox-0.12.5-1.centos7.x86_64.rpm";
    if (!installer.fileExists(wkhtmltopdfPath + "/" + wkhtmltopdfPackage)) {
        log("Tool wkHTMLtoPDF package :  " + wkhtmltopdfPath + "/" + wkhtmltopdfPackage + " not exists.");
        return;
    }
    log("Installing wkHTMLtoPDF tool ....");
    var command = "rpm2cpio " + wkhtmltopdfPackage + " | cpio -idmv";
    log(command);
    execute("cd " + wkhtmltopdfPath + "; " + command);
    execute("cd " + wkhtmltopdfPath + "; cp ./usr/local/bin/wkhtmltopdf .");
    log("Tool wkHTMLtoPDF installed successfully.");
}

function manageInstallationFolders() {
    var installationpath = findInstallationHomeFolder(installer.value("TargetDir"));
    // log("Removing folder Licenses");
    // execute("rm -rf " + installationpath + "/Licenses");
}

function logObjectDepthInfo(widget) {
    log("Start showObjectDepthInfo()");
    log(widget);
    try { log(JSON.stringify(widget)); } catch (e) { }
    for (key in widget) {
        try { log(key); } catch (e) { }
    }
    log("End showObjectDepthInfo()");
}