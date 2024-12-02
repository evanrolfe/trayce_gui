# -*- coding: utf-8 -*-

################################################################################
## Form generated from reading UI file 'ui_proto_defs_dialog.ui'
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
from PySide6.QtWidgets import (QApplication, QDialog, QFrame, QHBoxLayout,
    QHeaderView, QLabel, QPushButton, QSizePolicy,
    QSpacerItem, QTableView, QVBoxLayout, QWidget)

class Ui_ProtoDefsDialog(object):
    def setupUi(self, ProtoDefsDialog):
        if not ProtoDefsDialog.objectName():
            ProtoDefsDialog.setObjectName(u"ProtoDefsDialog")
        ProtoDefsDialog.resize(800, 600)
        self.verticalLayout = QVBoxLayout(ProtoDefsDialog)
        self.verticalLayout.setObjectName(u"verticalLayout")
        self.horizontalLayout = QHBoxLayout()
        self.horizontalLayout.setObjectName(u"horizontalLayout")
        self.label_3 = QLabel(ProtoDefsDialog)
        self.label_3.setObjectName(u"label_3")
        font = QFont()
        font.setPointSize(20)
        font.setBold(True)
        self.label_3.setFont(font)
        self.label_3.setAlignment(Qt.AlignmentFlag.AlignLeading|Qt.AlignmentFlag.AlignLeft|Qt.AlignmentFlag.AlignTop)

        self.horizontalLayout.addWidget(self.label_3)


        self.verticalLayout.addLayout(self.horizontalLayout)

        self.line = QFrame(ProtoDefsDialog)
        self.line.setObjectName(u"line")
        self.line.setFrameShape(QFrame.Shape.HLine)
        self.line.setFrameShadow(QFrame.Shadow.Sunken)

        self.verticalLayout.addWidget(self.line)

        self.protoDefsTable = QTableView(ProtoDefsDialog)
        self.protoDefsTable.setObjectName(u"protoDefsTable")

        self.verticalLayout.addWidget(self.protoDefsTable)

        self.verticalSpacer_2 = QSpacerItem(20, 1, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)

        self.verticalLayout.addItem(self.verticalSpacer_2)

        self.horizontalLayout_5 = QHBoxLayout()
        self.horizontalLayout_5.setObjectName(u"horizontalLayout_5")
        self.horizontalSpacer = QSpacerItem(40, 20, QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Minimum)

        self.horizontalLayout_5.addItem(self.horizontalSpacer)

        self.uploadButton = QPushButton(ProtoDefsDialog)
        self.uploadButton.setObjectName(u"uploadButton")
        self.uploadButton.setAutoDefault(False)

        self.horizontalLayout_5.addWidget(self.uploadButton)

        self.closeButton = QPushButton(ProtoDefsDialog)
        self.closeButton.setObjectName(u"closeButton")

        self.horizontalLayout_5.addWidget(self.closeButton)


        self.verticalLayout.addLayout(self.horizontalLayout_5)


        self.retranslateUi(ProtoDefsDialog)

        QMetaObject.connectSlotsByName(ProtoDefsDialog)
    # setupUi

    def retranslateUi(self, ProtoDefsDialog):
        ProtoDefsDialog.setWindowTitle(QCoreApplication.translate("ProtoDefsDialog", u"Intercept Docker", None))
        self.label_3.setText(QCoreApplication.translate("ProtoDefsDialog", u"GRPC Proto Files", None))
        self.uploadButton.setText(QCoreApplication.translate("ProtoDefsDialog", u"Browse", None))
        self.closeButton.setText(QCoreApplication.translate("ProtoDefsDialog", u"Close", None))
    # retranslateUi

