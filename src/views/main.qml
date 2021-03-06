import QtQuick 2.1
import QtAV 1.4
import QtGraphicalEffects 1.0
import QtQuick.Window 2.1
import Deepin.Locale 1.0
import Deepin.Widgets 1.0
import "../controllers"

Rectangle {
    id: root
    state: "normal"
    color: "transparent"
    // QT takes care of WORKAREA for you which is thoughtful indeed, but it cause
    // problems sometime, we should be careful in case that it changes height for
    // you suddenly.
    layer.enabled: true

    property var windowLastState: ""

    property real widthHeightScale: player.resolution.width / player.resolution.height
    property real actualScale: 1.0

    property bool hasResized: false
    property bool shouldAutoPlayNextOnInvalidFile: false

    property rect primaryRect: {
        return Qt.rect(0, 0, Screen.desktopAvailableWidth, Screen.desktopAvailableHeight)
    }

    // properties that used as ids
    property alias tooltip: tooltip_loader.item
    property alias open_file_dialog: open_file_dialog_loader.item
    property alias open_folder_dialog: open_folder_dialog_loader.item
    property alias open_url_dialog: open_url_dialog_loader.item
    property alias info_window: info_window_loader.item
    property alias preference_window: preference_window_loader.item
    property alias shortcuts_viewer: shortcuts_viewer_loader.item

    states: [
        State {
            name: "normal"

            PropertyChanges { target: main_window; width: root.width - program_constants.windowGlowRadius * 2;
                              height: root.height - program_constants.windowGlowRadius * 2; }
            PropertyChanges { target: titlebar; width: main_window.width; anchors.top: main_window.top }
            PropertyChanges { target: controlbar; width: main_window.width; anchors.bottom: main_window.bottom}
            PropertyChanges { target: playlist; height: main_window.height; anchors.right: main_window.right }
            PropertyChanges { target: player; fillMode: VideoOutput.Stretch }
        },
        State {
            name: "no_glow"

            PropertyChanges { target: main_window; width: root.width; height: root.height }
            PropertyChanges { target: titlebar; width: root.width; anchors.top: root.top }
            PropertyChanges { target: controlbar; width: root.width; anchors.bottom: root.bottom}
            PropertyChanges { target: playlist; height: root.height; anchors.right: root.right }
            PropertyChanges { target: player; fillMode: VideoOutput.PreserveAspectFit }
        }
    ]

    onStateChanged: {
        if (state == "normal") {
            windowView.setDeepinWindowShadowHint(windowView.windowGlowRadius)
        } else if (state == "no_glow") {
            windowView.setDeepinWindowShadowHint(0)
        }
    }

    Constants { id: program_constants }

    Component {
        id: tooltip_component

        ToolTip {
            window: windowView
            screenSize: primaryRect
        }
    }

    Component {
        id: open_file_dialog_component

        OpenFileDialog {
            onAccepted: {
                shouldAutoPlayNextOnInvalidFile = false

                if (fileUrls.length > 0) {
                    if (state == "open_video_file") {
                        _settings.lastOpenedPath = folder
                        main_controller.playPaths(fileUrls, true)
                    } else if (state == "open_subtitle_file") {
                        _settings.lastOpenedPath = folder
                        var filename = fileUrls[0].toString().replace("file://", "")

                        if (_utils.fileIsSubtitle(filename)) {
                            _subtitle_parser.file_name = filename
                        } else {
                            notifybar.show(dsTr("Invalid file") + ": " + filename)
                        }
                    } else if (state == "add_playlist_item") {
                        _settings.lastOpenedPath = folder

                        main_controller.playPaths(fileUrls, false)
                    } else if (state == "import_playlist") {
                        _settings.lastOpenedPlaylistPath = folder

                        var filename = fileUrls[0].toString().replace("file://", "")
                        main_controller.importPlaylistImpl(filename)
                    } else if (state == "export_playlist") {
                        _settings.lastOpenedPlaylistPath = folder

                        var filename = fileUrls[0].toString().replace("file://", "")
                        if (filename.toString().search(".dmpl") == -1) {
                            filename = filename + ".dmpl"
                        }
                        main_controller.exportPlaylistImpl(filename)
                    }
                }
            }
        }
    }

    Component {
        id: open_folder_dialog_component
        OpenFolderDialog {
            folder: _settings.lastOpenedPath || _utils.homeDir

            property bool playFirst: true

            onAccepted: {
                shouldAutoPlayNextOnInvalidFile = false

                var folderPath = fileUrl.toString()
                _settings.lastOpenedPath = folder // record last opened path
                main_controller.playPaths([folderPath], playFirst)
            }
        }
    }

    Component {
        id: open_url_dialog_component

        DInputDialog {
            message: dsTr("Please input the url of file played") + ": "
            confirmButtonLabel: dsTr("Confirm")
            cancelButtonLabel: dsTr("Cancel")

            cursorPosGetter: windowView

            property string lastInput: ""

            function open() {
                x = windowView.x + (windowView.width - width) / 2
                y = windowView.y + (windowView.height - height) / 2
                show()
            }

            onConfirmed: {
                var input = input.trim()

                if (input.search("://") == -1) {
                    notifybar.show(dsTr("The parse failed"))
                } else if (input != player.source) {
                    if (config.playerCleanPlaylistOnOpenNewFile) {
                        main_controller.clearPlaylist()
                    }
                    shouldAutoPlayNextOnInvalidFile = false
                    player.source = input
                }

                lastInput = input
            }

            onVisibleChanged: { if(visible) forceFocus() }
        }
    }

    Component {
        id: preference_window_component

        PreferenceWindow {}
    }

    Component {
        id: info_window_component

        InformationWindow {
            onCopyToClipboard: _utils.copyToClipboard(text)
        }
    }

    Component {
        id: shortcuts_viewer_component

        ShortcutsViewer {
            x: Math.max(0, Math.min(windowView.x + (windowView.width - width) / 2, Screen.width - width))
            y: Math.max(0, Math.min(windowView.y + (windowView.height - height) / 2, Screen.height - height))
        }
    }

    Loader {
        id: tooltip_loader
        asynchronous: true
        sourceComponent: tooltip_component
    }

    Loader {
        id: open_file_dialog_loader
        asynchronous: true
        sourceComponent: open_file_dialog_component
    }

    Loader {
        id: open_folder_dialog_loader
        asynchronous: true
        sourceComponent: open_folder_dialog_component
    }

    Loader {
        id: open_url_dialog_loader
        asynchronous: true
        sourceComponent: open_url_dialog_component
    }

    Loader {
        id: preference_window_loader
        asynchronous: true
        sourceComponent: preference_window_component
    }

    Loader {
        id: info_window_loader
        asynchronous: true
        sourceComponent:  info_window_component
    }

    Loader {
        id: shortcuts_viewer_loader
        asynchronous: true
        sourceComponent: shortcuts_viewer_component
    }


    // translation tools
    property var dssLocale: DLocale {
        domain: "deepin-movie"
    }
    function dsTr(s) {
        return dssLocale.dsTr(s)
    }

    function getSystemFontFamily() {
        var text = Qt.createQmlObject('import QtQuick 2.1; Text {}', root, "");
        return text.font.family
    }

    function initWindowSize() {
        if (config.playerApplyLastClosedSize) {
            hasResized = true
            main_controller._setSizeForRootWindowWithWidth(_settings.lastWindowWidth)
        } else {
            windowView.setWidth(windowView.defaultWidth)
            windowView.setHeight(windowView.defaultHeight)
        }
    }

    function resetWindowSize() {
        if (!config.playerApplyLastClosedSize) {
            windowView.setWidth(windowView.defaultWidth)
            windowView.setHeight(windowView.defaultHeight)
            player.source = ""
        }
    }

    function miniModeState() { return windowView.width == program_constants.miniModeWidth }

    function formatTime(millseconds) {
        if (millseconds <= 0) return "00:00:00";
        var secs = Math.ceil(millseconds / 1000)
        var hr = Math.floor(secs / 3600);
        var min = Math.floor((secs - (hr * 3600))/60);
        var sec = secs - (hr * 3600) - (min * 60);

        if (hr < 10) {hr = "0" + hr; }
        if (min < 10) {min = "0" + min;}
        if (sec < 10) {sec = "0" + sec;}
        if (!hr) {hr = "00";}
        return hr + ':' + min + ':' + sec;
    }

    function formatSize(capacity) {
        var teras = capacity / (1024 * 1024 * 1024 * 1024)
        capacity = capacity % (1024 * 1024 * 1024 * 1024)
        var gigas = capacity / (1024 * 1024 * 1024)
        capacity = capacity % (1024 * 1024 * 1024)
        var megas = capacity / (1024 * 1024)
        capacity = capacity % (1024 * 1024)
        var kilos = capacity / 1024

        return Math.floor(teras) ? teras.toFixed(1) + "TB" :
                Math.floor(gigas) ? gigas.toFixed(1) + "GB":
                Math.floor(megas) ? megas.toFixed(1) + "MB" :
                kilos + "KB"
    }

    function formatFilePath(file_path) {
        return file_path.indexOf("file://") != -1 ? file_path.substring(7) : file_path
    }

    function playPaths(pathList) {
        var pathList = JSON.parse(pathList)
        var pathsExceptUrls = new Array()
        var firstIsUrl = false
        for (var i = 0; i < pathList.length; i++) {
            if (!_utils.urlIsNativeFile(pathList[i])) {
                main_controller.addPlaylistStreamItem(pathList[i])
                if (i == 0) {
                    player.source = pathList[i]
                    firstIsUrl = true
                }
            } else {
                pathsExceptUrls.push(pathList[i])
            }
        }
        main_controller.playPaths(pathsExceptUrls, !firstIsUrl)
    }

    function showControls() {
        titlebar.show()
        controlbar.show()
        hide_controls_timer.restart()
    }

    function hideControls() {
        titlebar.hide()
        controlbar.hide()
        hide_controls_timer.stop()
    }

    function hideTransientWindows() {
        shortcuts_viewer.hide()
        resize_visual.hide()
    }

    function subtitleVisible() {
        return player.subtitleShow
    }

    function setSubtitleVisible(visible) {
        player.subtitleShow = visible;
    }

    // Utils functions
    function inRectCheck(point, rect) {
        return rect.x <= point.x && point.x <= rect.x + rect.width &&
        rect.y <= point.y && point.y <= rect.y + rect.height
    }

    function mouseInControlsArea() {
        var mousePos = windowView.getCursorPos()
        var mouseInTitleBar = inRectCheck(Qt.point(mousePos.x - windowView.x, mousePos.y - windowView.y),
                                            Qt.rect(0, 0, main_window.width, titlebar.height))
        var mouseInControlBar = inRectCheck(Qt.point(mousePos.x - windowView.x, mousePos.y - windowView.y),
                                            Qt.rect(0, main_window.height - controlbar.height,
                                                    main_window.width, controlbar.height))

        return mouseInTitleBar || mouseInControlBar
    }

    function mouseInPlaylistArea() {
        var mousePos = windowView.getCursorPos()
        return playlist.expanded && inRectCheck(Qt.point(mousePos.x - windowView.x, mousePos.y - windowView.y),
                                            Qt.rect(main_window.width - program_constants.playlistWidth, 0,
                                                program_constants.playlistWidth, main_window.height))
    }

    function mouseInPlaylistTriggerArea() {
        var mousePos = windowView.getCursorPos()
        return !playlist.expanded && inRectCheck(Qt.point(mousePos.x - windowView.x, mousePos.y - windowView.y),
                                            Qt.rect(main_window.width - program_constants.playlistTriggerThreshold, titlebar.height,
                                                    program_constants.playlistTriggerThreshold + 10, main_window.height - controlbar.height))
    }

    /* to perform like a newly started program  */
    function reset() {
        player.resetRotationFlip()
        root.state = "normal"
        titlebar.title = ""
        windowView.setTitle(dsTr("Deepin Movie"))
        resetWindowSize()
        _subtitle_parser.file_name = ""
        main_controller.stop()
        controlbar.reset()
        showControls()
    }

    // To check wether the player is stopped by the app or by the user
    // if it is ther user that stopped the player, we'll not play it automatically.
    property bool videoStoppedByAppFlag: false
    function monitorWindowState(state) {
        titlebar.windowNormalState = (state == Qt.WindowNoState)
        titlebar.windowFullscreenState = (state == Qt.WindowFullScreen)
        controlbar.windowFullscreenState = (state == Qt.WindowFullScreen)
        time_indicator.visibleSwitch = (state == Qt.WindowFullScreen && player.hasMedia)
        if (windowLastState != state) {
            if (config.playerPauseOnMinimized) {
                if (state == Qt.WindowMinimized) {
                    if (player.playbackState == MediaPlayer.PlayingState) {
                        main_controller.pause()
                        videoStoppedByAppFlag = true
                    }
                } else {
                    if (videoStoppedByAppFlag == true) {
                        main_controller.play()
                        videoStoppedByAppFlag = false
                    }
                }
            }
            windowLastState = state
        }
    }

    function monitorWindowClose() {
        _utils.screenSaverUninhibit()
        main_controller.recordVideoPosition(player.source, player.position)
        main_controller.recordVideoRotation(player.source, player.orientation)
        _database.setPlaylistContentCache(playlist.getContent())
        _settings.lastWindowWidth = windowView.width
        player.source && (_settings.lastPlayedFile = player.source)
    }

    Timer {
        id: auto_play_next_on_invalid_timer
        interval: 1000 * 2

        property url invalidFile: ""

        function startWidthFile(file) {
            invalidFile = file
            restart()
        }

        onTriggered: {
            main_controller.playNextOf(invalidFile)
        }
    }

    Timer {
        id: hide_controls_timer
        running: true
        interval: 1500

        onTriggered: {
            if (!mouseInControlsArea() && player.source && player.hasVideo) {
                hideControls()

                if (player.playbackState == MediaPlayer.PlayingState) {
                    windowView.setCursorVisible(false)
                }
            } else {
                hide_controls_timer.restart()
            }
        }
    }

    RectangularGlow {
        id: shadow
        anchors.fill: main_window
        glowRadius: program_constants.windowGlowRadius - 5
        spread: 0
        color: Qt.rgba(0, 0, 0, 1)
        cornerRadius: 10
        visible: true
    }

    Rectangle {
        id: main_window
        width: root.width - program_constants.windowGlowRadius * 2
        height: root.height - program_constants.windowGlowRadius * 2
        clip: true
        color: "black"
        anchors.centerIn: parent

        Rectangle {
            id: bg
            color: "#000000"
            visible: !player.visible
            anchors.fill: parent
            Image { anchors.centerIn: parent; source: "image/background.png" }
        }
    }

    Player {
        id: player
        muted: config.playerMuted
        volume: config.playerVolume
        visible: hasVideo && source != ""

        subtitleShow: config.subtitleAutoLoad
        subtitleFontSize: Math.floor(config.subtitleFontSize * main_window.width / windowView.defaultWidth)
        subtitleFontFamily: config.subtitleFontFamily || getSystemFontFamily()
        subtitleFontColor: config.subtitleFontColor
        subtitleFontBorderSize: config.subtitleFontBorderSize
        subtitleFontBorderColor: config.subtitleFontBorderColor
        subtitleVerticalPosition: config.subtitleVerticalPosition

        anchors.fill: main_window

        // theses properties are mainly used in onStopped.
        // because we can't ensure the source and position info available every
        // time the onStopped handler executes.
        property url lastVideoSource: ""
        property int lastVideoPosition: 0
        property int lastVideoDuration: 0

        onResolutionChanged: main_controller.playerResolutionChanged()

        // onSourceChanged doesn't ensures that the file is playable, this one did.
        // 2014/9/16 add: not ensures url playable, either
        onPlaying: {
            notifybar.hide()
            auto_play_next_on_invalid_timer.stop()
            main_controller.setWindowTitle(_utils.getTitleFromUrl(player.source))

            _utils.screenSaverInhibit()

            lastVideoSource = source
            lastVideoDuration = duration
            if (config.playerFullscreenOnOpenFile) main_controller.fullscreen()

            if (_utils.urlIsNativeFile(source)) {
                main_controller.playPaths([source.toString()], false)
            } else {
                main_controller.addPlaylistStreamItem(source)
            }
        }

        onStopped: {
            _utils.screenSaverUninhibit()
            main_controller.recordVideoPosition(lastVideoSource, lastVideoPosition)

            var videoPLayedOut = (lastVideoDuration - lastVideoPosition) < program_constants.videoEndsThreshold

            if (_utils.urlIsNativeFile(lastVideoSource)) {
                if (videoPLayedOut) {
                    shouldAutoPlayNextOnInvalidFile = true
                    main_controller.playNextOf(_settings.lastPlayedFile)
                }
            }
        }

        onPlaybackStateChanged: {
            controlbar.videoPlaying = player.playbackState == MediaPlayer.PlayingState
        }

        onPositionChanged: {
            position != 0 && (lastVideoPosition = position)
            subtitleContent = _subtitle_parser.get_subtitle_at(position - player.subtitleDelay)
            controlbar.percentage = position / player.duration
        }

        property bool resetPlayHistoryCursor: true
        onSourceChanged: {
            resetRotationFlip()

            if (source.toString().trim()) {
                _settings.lastPlayedFile = source
                _database.appendPlayHistoryItem(source, resetPlayHistoryCursor)
                _subtitle_parser.set_subtitle_from_movie(source)
                main_controller.recordVideoPosition(lastVideoSource, lastVideoPosition)
                resetPlayHistoryCursor = true

                main_controller.seekToLastPlayed()

                var rotation = main_controller.fetchVideoRotation(source)
                var rotateClockwiseCount = Math.abs(Math.round((rotation % 360 - 360) % 360 / 90))
                for (var i = 0; i < rotateClockwiseCount; i++) {
                    main_controller.rotateClockwise()
                }
            }
        }

        onErrorChanged: {
            print(error)
            print(errorString)
            // if (movieInfo.movie_file.toString() == open_url_dialog.lastInput.toString())
            // {
            //     playlist.removeItem(source)
            // }

            // switch(error) {
            //     case MediaPlayer.NetworkError:
            //     case MediaPlayer.FormatError:
            //     case MediaPlayer.ResourceError:
            //     movieInfo.fileInvalid()
            //     break
            // }

            // open_url_dialog.lastInput = ""
        }
    }

    TimeIndicator {
        id: time_indicator
        visible: visibleSwitch && !titlebar.visible
        percentage: controlbar.percentage

        property bool visibleSwitch: false

        anchors.top: main_window.top
        anchors.right: main_window.right
        anchors.topMargin: 10
        anchors.rightMargin: 10
    }

    MainController {
        id: main_controller
        window: root
    }

    Notifybar {
        id: notifybar
        width: main_window.width / 2
        anchors.top: root.top
        anchors.left: root.left
        anchors.topMargin: 40
        anchors.leftMargin: 30
    }

    Playlist {
        id: playlist
        width: 0
        visible: false
        window: windowView
        maxWidth: main_window.width * 0.6
        currentPlayingSource: player.source
        tooltipItem: tooltip
        canExpand: controlbar.status != "minimal"
        anchors.right: main_window.right
        anchors.verticalCenter: parent.verticalCenter

        onShowed: root.hideControls()

        onNewSourceSelected: {
            shouldAutoPlayNextOnInvalidFile = false
            player.source = path
        }
        onModeButtonClicked: _menu_controller.show_mode_menu()
        onAddButtonClicked: _menu_controller.show_add_button_menu()

        onMoveInWindowButtons: titlebar.showForPlaylist()
        onMoveOutWindowButtons: titlebar.hideForPlaylist()

        onCleared: main_controller.clearPlaylist()
        onItemRemoved: main_controller.removePlaylistItem(url)
        onCategoryRemoved: main_controller.removePlaylistCategory(name)
    }

    TitleBar {
        id: titlebar
        state: root.miniModeState() ? "minimal" : "normal"
        visible: false
        window: windowView
        windowStaysOnTop: windowView.staysOnTop
        anchors.horizontalCenter: main_window.horizontalCenter
        tooltipItem: tooltip

        onMenuButtonClicked: main_controller.showMainMenu()
        onMinButtonClicked: main_controller.minimize()
        onMaxButtonClicked: windowNormalState ? main_controller.maximize() : main_controller.normalize()
        onCloseButtonClicked: main_controller.close()

        onQuickNormalSize: main_controller.setScale(1)
        onQuickOneHalfSize: main_controller.setScale(1.5)
        onQuickToggleFullscreen: main_controller.toggleFullscreen()
        onQuickToggleTop: main_controller.toggleStaysOnTop()
    }

    ControlBar {
        id: controlbar
        videoPlayer: player
        visible: false
        window: windowView
        volume: config.playerVolume
        percentage: player.position / player.duration
        muted: config.playerMuted
        widthHeightScale: root.widthHeightScale
        dragbarVisible: root.state == "normal"
        timeInfoVisible: player.source != "" && player.hasMedia && player.duration != 0
        tooltipItem: tooltip
        videoSource: player.source

        anchors.horizontalCenter: main_window.horizontalCenter

        Timer {
            id: delay_seek_timer
            interval: 500
            property int destPos

            onTriggered: player.seek(destPos)
        }

        onPreviousButtonClicked: { main_controller.playPrevious() }
        onNextButtonClicked: { main_controller.playNext() }

        onChangeVolume: { main_controller.setVolume(volume) }
        onMutedSet: { main_controller.setMute(muted) }

        onToggleFullscreenClicked: main_controller.toggleFullscreen()

        onPlayStopButtonClicked: { root.reset() }
        onPlayPauseButtonClicked: { main_controller.togglePlay() }
        onOpenFileButtonClicked: { main_controller.openFile() }
        onPlaylistButtonClicked: { playlist.toggleShow() }
        onPercentageSet: {
            if (player.duration) {
                delay_seek_timer.destPos = player.duration * percentage
                delay_seek_timer.restart()
            }
        }
    }

    ResizeEdge { id: resize_edge }
    ResizeVisual {
        id: resize_visual

        frameY: windowView.y
        frameX: windowView.x
        frameWidth: root.width
        frameHeight: root.height
        widthHeightScale: root.widthHeightScale
    }

    Component.onCompleted: showControls()
}
