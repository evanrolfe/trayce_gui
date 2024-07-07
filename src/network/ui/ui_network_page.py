# -*- coding: utf-8 -*-

################################################################################
## Form generated from reading UI file 'ui_network_page.ui'
##
## Created by: Qt User Interface Compiler version 6.7.2
##
## WARNING! All changes made in this file will be lost when recompiling UI file!
################################################################################

from PySide6.QtCore import (QCoreApplication, QDate, QDateTime, QLocale,
    QMetaObject, QObject, QPoint, QRect,
    QSize, QTime, QUrl, Qt)
from PySide6.QtGui import (QBrush, QColor, QConicalGradient, QCursor,
    QFont, QFontDatabase, QGradient, QIcon,
    QImage, QKeySequence, QLinearGradient, QPainter,
    QPalette, QPixmap, QRadialGradient, QTransform)
from PySide6.QtWidgets import (QApplication, QPlainTextEdit, QSizePolicy, QSplitter,
    QTabWidget, QVBoxLayout, QWidget)

from network.widgets.flow_table_container import FlowTableContainer

class Ui_NetworkPage(object):
    def setupUi(self, NetworkPage):
        if not NetworkPage.objectName():
            NetworkPage.setObjectName(u"NetworkPage")
        NetworkPage.resize(880, 609)
        self.verticalLayout = QVBoxLayout(NetworkPage)
        self.verticalLayout.setSpacing(0)
        self.verticalLayout.setObjectName(u"verticalLayout")
        self.verticalLayout.setContentsMargins(0, 0, 0, 0)
        self.splitter_2 = QSplitter(NetworkPage)
        self.splitter_2.setObjectName(u"splitter_2")
        self.splitter_2.setOrientation(Qt.Horizontal)
        self.flowTableContainer = FlowTableContainer(self.splitter_2)
        self.flowTableContainer.setObjectName(u"flowTableContainer")
        self.splitter_2.addWidget(self.flowTableContainer)
        self.splitter = QSplitter(self.splitter_2)
        self.splitter.setObjectName(u"splitter")
        self.splitter.setOrientation(Qt.Vertical)
        self.requestTabs = QTabWidget(self.splitter)
        self.requestTabs.setObjectName(u"requestTabs")
        self.requestText = QPlainTextEdit()
        self.requestText.setObjectName(u"requestText")
        self.requestTabs.addTab(self.requestText, "")
        self.requestBodyText = QPlainTextEdit()
        self.requestBodyText.setObjectName(u"requestBodyText")
        self.requestTabs.addTab(self.requestBodyText, "")
        self.splitter.addWidget(self.requestTabs)
        self.responseTabs = QTabWidget(self.splitter)
        self.responseTabs.setObjectName(u"responseTabs")
        self.responseText = QPlainTextEdit()
        self.responseText.setObjectName(u"responseText")
        self.responseTabs.addTab(self.responseText, "")
        self.responseBodyText = QPlainTextEdit()
        self.responseBodyText.setObjectName(u"responseBodyText")
        self.responseTabs.addTab(self.responseBodyText, "")
        self.splitter.addWidget(self.responseTabs)
        self.splitter_2.addWidget(self.splitter)

        self.verticalLayout.addWidget(self.splitter_2)


        self.retranslateUi(NetworkPage)

        QMetaObject.connectSlotsByName(NetworkPage)
    # setupUi

    def retranslateUi(self, NetworkPage):
        NetworkPage.setWindowTitle(QCoreApplication.translate("NetworkPage", u"Form", None))
        self.requestTabs.setTabText(self.requestTabs.indexOf(self.requestText), QCoreApplication.translate("NetworkPage", u"Request", None))
        self.requestTabs.setTabText(self.requestTabs.indexOf(self.requestBodyText), QCoreApplication.translate("NetworkPage", u"Body", None))
        self.responseTabs.setTabText(self.responseTabs.indexOf(self.responseText), QCoreApplication.translate("NetworkPage", u"Response", None))
        self.responseTabs.setTabText(self.responseTabs.indexOf(self.responseBodyText), QCoreApplication.translate("NetworkPage", u"Body", None))
    # retranslateUi

