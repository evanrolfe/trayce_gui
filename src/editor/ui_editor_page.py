# -*- coding: utf-8 -*-

################################################################################
## Form generated from reading UI file 'ui_editor_page.ui'
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
from PySide6.QtWidgets import (QApplication, QPushButton, QSizePolicy, QWidget)

class Ui_EditorPage(object):
    def setupUi(self, EditorPage):
        if not EditorPage.objectName():
            EditorPage.setObjectName(u"EditorPage")
        self.centralWidget = QWidget(EditorPage)
        self.centralWidget.setObjectName(u"centralWidget")
        self.pushButton = QPushButton(self.centralWidget)
        self.pushButton.setObjectName(u"pushButton")
        self.pushButton.setGeometry(QRect(320, 270, 90, 28))

        self.retranslateUi(EditorPage)

        QMetaObject.connectSlotsByName(EditorPage)
    # setupUi

    def retranslateUi(self, EditorPage):
        self.pushButton.setText(QCoreApplication.translate("EditorPage", u"Editor!!!", None))
        pass
    # retranslateUi

