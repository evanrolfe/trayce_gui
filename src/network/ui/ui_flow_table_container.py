# -*- coding: utf-8 -*-

################################################################################
## Form generated from reading UI file 'ui_flow_table_container.ui'
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
from PySide6.QtWidgets import (QApplication, QHBoxLayout, QHeaderView, QLineEdit,
    QPushButton, QSizePolicy, QVBoxLayout, QWidget)

from network.widgets.hoverable_table_view import HoverableTableView

class Ui_FlowTableContainer(object):
    def setupUi(self, FlowTableContainer):
        if not FlowTableContainer.objectName():
            FlowTableContainer.setObjectName(u"FlowTableContainer")
        FlowTableContainer.resize(321, 232)
        self.verticalLayout = QVBoxLayout(FlowTableContainer)
        self.verticalLayout.setSpacing(0)
        self.verticalLayout.setObjectName(u"verticalLayout")
        self.verticalLayout.setContentsMargins(0, 0, 0, 0)
        self.searchLayout = QHBoxLayout()
        self.searchLayout.setSpacing(4)
        self.searchLayout.setObjectName(u"searchLayout")
        self.searchLayout.setContentsMargins(4, 6, 4, 6)
        self.searchBox = QLineEdit(FlowTableContainer)
        self.searchBox.setObjectName(u"searchBox")

        self.searchLayout.addWidget(self.searchBox)

        self.searchBtn = QPushButton(FlowTableContainer)
        self.searchBtn.setObjectName(u"searchBtn")
        self.searchBtn.setCursor(QCursor(Qt.CursorShape.PointingHandCursor))

        self.searchLayout.addWidget(self.searchBtn)

        self.containersBtn = QPushButton(FlowTableContainer)
        self.containersBtn.setObjectName(u"containersBtn")
        self.containersBtn.setCursor(QCursor(Qt.CursorShape.PointingHandCursor))

        self.searchLayout.addWidget(self.containersBtn)


        self.verticalLayout.addLayout(self.searchLayout)

        self.flowsTable = HoverableTableView(FlowTableContainer)
        self.flowsTable.setObjectName(u"flowsTable")

        self.verticalLayout.addWidget(self.flowsTable)


        self.retranslateUi(FlowTableContainer)

        QMetaObject.connectSlotsByName(FlowTableContainer)
    # setupUi

    def retranslateUi(self, FlowTableContainer):
        self.searchBox.setPlaceholderText(QCoreApplication.translate("FlowTableContainer", u"Search", None))
        self.searchBtn.setText(QCoreApplication.translate("FlowTableContainer", u"Filters", None))
        self.containersBtn.setText(QCoreApplication.translate("FlowTableContainer", u"Containers", None))
        pass
    # retranslateUi

