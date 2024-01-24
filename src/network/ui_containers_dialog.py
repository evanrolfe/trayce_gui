# -*- coding: utf-8 -*-

################################################################################
## Form generated from reading UI file 'ui_containers_dialog.ui'
##
## Created by: Qt User Interface Compiler version 6.6.1
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
from PySide6.QtWidgets import (QApplication, QDialog, QFrame, QHBoxLayout,
    QHeaderView, QLabel, QPushButton, QSizePolicy,
    QSpacerItem, QTableView, QVBoxLayout, QWidget)

class Ui_ContainersDialog(object):
    def setupUi(self, ContainersDialog):
        if not ContainersDialog.objectName():
            ContainersDialog.setObjectName(u"ContainersDialog")
        ContainersDialog.resize(800, 600)
        self.verticalLayout = QVBoxLayout(ContainersDialog)
        self.verticalLayout.setObjectName(u"verticalLayout")
        self.horizontalLayout = QHBoxLayout()
        self.horizontalLayout.setObjectName(u"horizontalLayout")
        self.label_3 = QLabel(ContainersDialog)
        self.label_3.setObjectName(u"label_3")
        font = QFont()
        font.setPointSize(20)
        font.setBold(True)
        self.label_3.setFont(font)
        self.label_3.setAlignment(Qt.AlignLeading|Qt.AlignLeft|Qt.AlignTop)

        self.horizontalLayout.addWidget(self.label_3)


        self.verticalLayout.addLayout(self.horizontalLayout)

        self.line = QFrame(ContainersDialog)
        self.line.setObjectName(u"line")
        self.line.setFrameShape(QFrame.HLine)
        self.line.setFrameShadow(QFrame.Sunken)

        self.verticalLayout.addWidget(self.line)

        self.verticalLayout_2 = QVBoxLayout()
        self.verticalLayout_2.setSpacing(10)
        self.verticalLayout_2.setObjectName(u"verticalLayout_2")
        self.verticalLayout_2.setContentsMargins(-1, -1, -1, 20)
        self.label = QLabel(ContainersDialog)
        self.label.setObjectName(u"label")
        self.label.setAlignment(Qt.AlignLeading|Qt.AlignLeft|Qt.AlignTop)
        self.label.setWordWrap(True)

        self.verticalLayout_2.addWidget(self.label)

        self.line2 = QFrame(ContainersDialog)
        self.line2.setObjectName(u"line2")
        self.line2.setFrameShape(QFrame.HLine)
        self.line2.setFrameShadow(QFrame.Sunken)

        self.verticalLayout_2.addWidget(self.line2)


        self.verticalLayout.addLayout(self.verticalLayout_2)

        self.containersTable = QTableView(ContainersDialog)
        self.containersTable.setObjectName(u"containersTable")

        self.verticalLayout.addWidget(self.containersTable)

        self.verticalSpacer_2 = QSpacerItem(20, 1, QSizePolicy.Minimum, QSizePolicy.Expanding)

        self.verticalLayout.addItem(self.verticalSpacer_2)

        self.horizontalLayout_5 = QHBoxLayout()
        self.horizontalLayout_5.setObjectName(u"horizontalLayout_5")
        self.horizontalSpacer = QSpacerItem(40, 20, QSizePolicy.Expanding, QSizePolicy.Minimum)

        self.horizontalLayout_5.addItem(self.horizontalSpacer)

        self.cancelButton = QPushButton(ContainersDialog)
        self.cancelButton.setObjectName(u"cancelButton")
        self.cancelButton.setAutoDefault(False)

        self.horizontalLayout_5.addWidget(self.cancelButton)

        self.saveButton = QPushButton(ContainersDialog)
        self.saveButton.setObjectName(u"saveButton")

        self.horizontalLayout_5.addWidget(self.saveButton)


        self.verticalLayout.addLayout(self.horizontalLayout_5)


        self.retranslateUi(ContainersDialog)

        QMetaObject.connectSlotsByName(ContainersDialog)
    # setupUi

    def retranslateUi(self, ContainersDialog):
        ContainersDialog.setWindowTitle(QCoreApplication.translate("ContainersDialog", u"Intercept Docker", None))
        self.label_3.setText(QCoreApplication.translate("ContainersDialog", u"Intercept running Docker containers", None))
        self.label.setText(QCoreApplication.translate("ContainersDialog", u"Select which containers you want to intercept.", None))
        self.cancelButton.setText(QCoreApplication.translate("ContainersDialog", u"Cancel", None))
        self.saveButton.setText(QCoreApplication.translate("ContainersDialog", u"Save", None))
    # retranslateUi

