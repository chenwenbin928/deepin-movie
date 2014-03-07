import QtQuick 2.1
import QtMultimedia 5.0
import QtGraphicalEffects 1.0

Item {
    id: control_bar
    height: program_constants.controlbarHeight
    
    property url videoSource
    property int position: 0
    property alias percentage: progressbar.percentage

    signal showed ()
    signal hided ()

    function show() {
    }

    function hide() {
    }

    function showWithAnimation() {
        showingBottomPanelAnimation.start()
    }

    function hideWithAnimation() {
        hidingBottomPanelAnimation.start()
    }

    LinearGradient {
        id: bottomPanelBackround

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 100
        start: Qt.point(0, 0)
        end: Qt.point(0, height)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00000000"}
            GradientStop { position: 1.0; color: "#FF000000"}
        }
    }

    Column {
        ProgressBar {
            id: progressbar
            width: parent.parent.width

            Preview {
                id: videoPreview
                source: movieInfo.movie_file
                visible: false
            }
            
            onMouseOver: {
                videoPreview.visible = true
                videoPreview.x = Math.min(Math.max(mouse.x - videoPreview.width / 2, 0),
                                          width - videoPreview.width)
                videoPreview.y = y - videoPreview.height

                var mouseX = mouse.x
                var mouseY = mouse.y
                
                if (mouseX <= videoPreview.cornerWidth / 2) {
                    videoPreview.cornerPos = mouseX + videoPreview.cornerWidth / 2
                    videoPreview.cornerType = "left"
                } else if (mouseX >= width - videoPreview.cornerWidth / 2) {
                    videoPreview.cornerPos = mouseX - width + videoPreview.width - videoPreview.cornerWidth / 2
                    videoPreview.cornerType = "right"
                } else if (mouseX < videoPreview.width / 2) {
                    videoPreview.cornerPos = mouseX
                    videoPreview.cornerType = "center"
                } else if (mouseX >= width - videoPreview.width / 2) {
                    videoPreview.cornerPos = mouseX - width + videoPreview.width
                    videoPreview.cornerType = "center"
                } else {
                    videoPreview.cornerPos = videoPreview.width / 2
                    videoPreview.cornerType = "center"
                }
                videoPreview.seek(mouseX / width)
            }
            
            onMouseExit: {
                videoPreview.visible = false
            }
        }

        Item {
            id: buttonArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 34

            Row {
                id: leftButtonArea
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 20

                ToggleButton {
                    id: playerList
                    imageName: "image/player_list"
                    anchors.verticalCenter: parent.verticalCenter
                /* active: playlistPanel.width == showWidth */
                }

                ToggleButton {
                    id: playerConfig
                    imageName: "image/player_config"
                    anchors.verticalCenter: parent.verticalCenter
                    active: false
                }
            }

            Row {
                id: middleButtonArea
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                ImageButton {
                    id: playerOpen
                    imageName: "image/player_open"
                    anchors.verticalCenter: playerPlay.verticalCenter
                }

                Space {
                    width: 46
                }

                ImageButton {
                    id: playerBackward
                    imageName: "image/player_backward"
                    anchors.verticalCenter: playerPlay.verticalCenter
                }

                Space {
                    width: 28
                }

                ImageButton {
                    id: playerPlay
                    imageName: player.playbackState == MediaPlayer.PlayingState ? "image/player_pause" : "image/player_play"
                    onClicked: {
                        toggle()
                    }
                }

                Space {
                    width: 28
                }

                ImageButton {
                    id: playerForward
                    imageName: "image/player_forward"
                    anchors.verticalCenter: playerPlay.verticalCenter
                }

                Space {
                    width: 46
                }

                VolumeButton {
                    id: playerVolume
                    anchors.verticalCenter: parent.verticalCenter

                    onInVolumebar: {
                        hidingTimer.stop()
                    }

                    onChangeVolume: {
                        video.volume = playerVolume.volume

                        notifybar.show("image/notify_volume.png", "音量: " + Math.round(video.volume * 100) + "%")
                    }

                    onClickMute: {
                        video.muted = !playerVolume.active

                        if (video.muted) {
                            notifybar.show("image/notify_volume.png", "静音")
                        } else {
                            notifybar.show("image/notify_volume.png", "音量: " + Math.round(player.volume * 100) + "%")
                        }
                    }
                }
            }

            Row {
                id: rightButtonArea
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                Text {
                    id: playTime
                    anchors.verticalCenter: parent.verticalCenter
                    text: formatTime(control_bar.position) + " / " + formatTime(movieInfo.movie_duration)
                    color: Qt.rgba(100, 100, 100, 1)
                    font.pixelSize: 12
                }
            }
        }
    }

    PropertyAnimation {
        id: showingBottomPanelAnimation
        target: parent
        property: "height"
        to: program_constants.controlbarHeight
        duration: 100
        easing.type: Easing.OutQuint

        onStopped: parent.showed()
    }

    PropertyAnimation {
        id: hidingBottomPanelAnimation
        target: parent
        property: "height"
        to: 0
        duration: 100
        easing.type: Easing.OutQuint

        onStopped: parent.hided()
    }
}