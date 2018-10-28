import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import "lib"
import "lib/Requests.js" as Requests

Item {
	id: widget

	Plasmoid.icon: plasmoid.file("", "icons/octicon-mark-github.svg")
	Plasmoid.backgroundHints: plasmoid.configuration.showBackground ? PlasmaCore.Types.DefaultBackground : PlasmaCore.Types.NoBackground
	Plasmoid.hideOnWindowDeactivate: !plasmoid.userConfiguring

	readonly property bool hasRepo: plasmoid.configuration.user && plasmoid.configuration.repo
	readonly property string repoString: plasmoid.configuration.user + '/' + plasmoid.configuration.repo
	readonly property string issueState: plasmoid.configuration.issueState
	readonly property string issuesUrl: 'https://api.github.com/repos/' + repoString + '/issues?state=' + issueState

	property var issuesModel: []

	Octicons { id: octicons }

	Plasmoid.fullRepresentation: FullRepresentation {}

	function updateIssuesModel() {
		if (widget.hasRepo) {
			Requests.getJSON({
				url: issuesUrl
			}, function(err, data, xhr){
				console.log(err)
				console.log(data)
				widget.issuesModel = data
			})
		} else {
			widget.issuesModel = []
		}
	}
	Timer {
		id: debouncedUpdateIssuesModel
		interval: 400
		onTriggered: {
			console.log('[githubissues] debouncedUpdateIssuesModel.onTriggered')
			widget.updateIssuesModel()
		}
	}
	Timer {
		id: updateModelTimer
		running: true
		repeat: true
		interval: plasmoid.configuration.updateIntervalInMinutes * 60 * 1000
		onTriggered: {
			console.log('[githubissues] updateModelTimer.onTriggered')
			debouncedUpdateIssuesModel.restart()
		}
	}

	Connections {
		target: plasmoid.configuration
		onUserChanged: debouncedUpdateIssuesModel.restart()
		onRepoChanged: debouncedUpdateIssuesModel.restart()
		onIssueStateChanged: debouncedUpdateIssuesModel.restart()
	}

	function action_refresh() {
		debouncedUpdateIssuesModel.restart()
	}

	Component.onCompleted: {
		plasmoid.setAction("refresh", i18n("Refresh"), "view-refresh")

		updateIssuesModel()

		// plasmoid.action("configure").trigger() // Uncomment to test config window
	}
}
