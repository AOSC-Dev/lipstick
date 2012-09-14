
/*
 * main.qml
 *
 * Copyright (c) 2011 - Tom Swindell <t.swindell@rubyx.co.uk>
 * Copyright (c) 2012 - Timur Kristóf <venemo@fedoraproject.org>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import QtQuick 1.1
import QtMobility.sensors 1.2
import org.nemomobile.lipstick 0.1

Item {
    id: main
    width: initialSize.width
    height: initialSize.height

    FontLoader { id: textFont; source: "fonts/HelveticaNeueLight.ttf" }
    FontLoader { id: headerFont; source: "fonts/HelveticaNeueUltraLight.ttf" }

    Item {
        property bool isPortrait: true
        property bool closeApplicationEnabled: false
        id: desktop
        anchors.top: parent.top
        anchors.left: parent.left
        width: isPortrait ? main.height : main.width
        height: isPortrait ? main.width : main.height
        transform: Rotation {
            id: desktopRotation;
            origin.x: desktop.isPortrait ? main.height / 2 : 0;
            origin.y: desktop.isPortrait ? main.height / 2 : 0;
            angle: desktop.isPortrait ? -90 : 0
        }

        Image {
            id: background
            source: 'images/graphics-wallpaper-home.jpg'
            x: 0
            y: -(dashboard.contentY / 3) - clock.height
            width: parent.width
            fillMode: Image.PreserveAspectCrop
        }

        Rectangle {
            color: "black"
            anchors.fill: parent
            opacity: (Math.abs(-dashboard.contentY) / dashboard.contentHeight)
        }

        Image {
            id: gradient
            source: "images/home-gradient-ramp.png"
            anchors.fill: parent
        }

        Flickable {
            id: dashboard
            anchors.fill: parent
            anchors.topMargin: - clock.height

            property int currentPage: 0
            property int maxPages: 0
            property int savedContentY: 0

            Connections {
                target: dashContent
                onHeightChanged: {
                    dashboard.maxPages = Math.ceil(dashContent.height / dashboard.height)
                    dashboard.contentHeight = (dashboard.maxPages) * dashboard.height

                    // TODO: we should recheck our page position and reset contentY if need be
                }
            }

            SpringAnimation on contentY {
                id: yBehavior
                spring: 3
                damping: 0.2
                mass: 0.3
            }

            onContentYChanged: {
                if (contentY < -10 && !clock.running)
                    clock.start();
                else if (contentY > -10 && clock.running)
                    clock.stop();
            }

            onMovementStarted: {
                savedContentY = contentY
                yBehavior.stop()
            }

            onFlickStarted: {
                interactive = false
            }


            onFlickEnded: {
                interactive = true
                var delta = dashboard.contentY - dashboard.savedContentY
                delta = delta / dashboard.height
                
                if (delta > 0.10) {
                    // snap down
                    dashboard.currentPage = dashboard.currentPage + 1 
                } else if (delta < -0.10) {
                    // snap up
                    dashboard.currentPage = dashboard.currentPage - 1 
                }
            }

            onMovementEnded: {
                snapToCurrentPage()
            }

            function snapToCurrentPage() {
                // bounce back
                if (dashboard.currentPage < 0)
                    dashboard.currentPage = 0 
                else if (dashboard.currentPage > dashboard.maxPages - 1)
                    dashboard.currentPage = dashboard.maxPages - 1
                 
                var newY = dashboard.currentPage * (dashboard.height - clock.height)
                
                yBehavior.from = dashboard.contentY
                yBehavior.to = newY
                yBehavior.start()
            }

            Column {
                id: dashContent
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                Clock {
                    id: clock
                    width: parent.width
                }

                Switcher {
                    id: switcher
                    width: parent.width
                    height: dashboard.height - launcher.cellHeight - clock.height
                }

                Launcher {
                    id: launcher
                    width: parent.width

                    onAppLaunchingStarted: {
                        dashboard.currentPage = 0
                        yBehavior.stop()
                        dashboard.contentY = 0
                    }
                }
            }
        }

        // TODO: does not match jolla UI
        Lockscreen {
            height: desktop.height
            width: desktop.width
            z: 200
        }
    }
}
