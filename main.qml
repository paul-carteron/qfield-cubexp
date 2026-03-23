import QtQuick 
import QtQuick.Controls 
import QtQuick.Layouts  

import QtCore

import org.qfield  
import org.qgis
import Theme  

import "qrc:/qml" as QFieldItems

Item {
    id: plugin
    parent: iface.mapCanvas() 
    anchors.fill: parent
        
    property var mainWindow: iface.mainWindow();
    property string prfMode: "Toutes"
    property string displayMode: "variation"

    Loader {
        id: pluginLoader
        active: false
        anchors.fill: parent
        source: Qt.resolvedUrl("./components/VarTable.qml")

        onLoaded: {
            item.model = varListModel
            item.prfMode = prfMode
        }
        
    }

    // open and close the Plugin
    QfToolButton {
        id: varPrinting
        iconSource: 'ic_axe_24dp.svg'
        iconColor: Theme.mainColor
        bgcolor: Theme.darkGray
        round: true

        onClicked: {
            pluginLoader.active = !pluginLoader.active;
            if (pluginLoader.active) {
                loadVarBy(displayMode)
            }
        }

        onPressAndHold: {
            loadPrf()
            displaySelectionDialog.open()
        }
    }

    // load the buttons
    Component.onCompleted: {
        iface.addItemToPluginsToolbar(varPrinting)
    }

    Dialog {
        id: displaySelectionDialog
        parent: mainWindow.contentItem
        visible: false
        modal: true
        font: Theme.defaultFont
        standardButtons: Dialog.Ok | Dialog.Cancel
        title: qsTr("Paramétrage des résultats")

        anchors.centerIn: parent

        ColumnLayout {
            spacing: 10
            anchors.fill: parent
            
            Label {
                text: qsTr("Sélectionner la PRF :")
                font.bold: true
            }

            QfComboBox {
                id: comboBoxVarPrf
                Layout.fillWidth: true

                textRole: "prf"
                valueRole: "prf"
                model: prfListModel
            }

            Label {
                text: qsTr("Mode d'affichage :")
                font.bold: true
            }

            QfComboBox {
                id: comboBoxDisplayMode
                Layout.fillWidth: true

                textRole: "name"
                valueRole: "value"
                model: ListModel {
                    ListElement { name: "Toutes essences"; value: "all" }
                    ListElement { name: "Par type"; value: "type" }
                    ListElement { name: "Par essence"; value: "essence" }
                    ListElement { name: "Par qualité"; value: "variation" }
                }
            }

        }
    
        onAccepted: {
            mainWindow.displayToast(qsTr("Mode d'affichage '%1' sélectionné !").arg(comboBoxDisplayMode.currentText));
            displayMode = comboBoxDisplayMode.currentValue
            prfMode = comboBoxVarPrf.currentValue
            loadVarBy(displayMode)
        }

        onOpened: {
            for (let i = 0; i < prfListModel.count; i++) {
                if (prfListModel.get(i).prf === prfMode)
                    comboBoxVarPrf.currentIndex = i
            }

            for (let i = 0; i < comboBoxDisplayMode.model.count; i++) {
                if (comboBoxDisplayMode.model.get(i).value === displayMode) 
                    comboBoxDisplayMode.currentIndex = i
            }
        }
    }

    ListModel {
        id: prfListModel
    }

    function loadPrf() {
        let arbres = qgisProject.mapLayersByName("Arbres")[0];
        if (!arbres) {
            iface.logMessage("Layer 'Arbres' not found.");
            return;
        }

        prfListModel.clear()
        prfListModel.append({ prf: "Toutes" });
        
        let uniquePrfSet = new Set();
        let it = LayerUtils.createFeatureIteratorFromExpression(arbres, "1=1");
        while (it.hasNext()) {
            let feature = it.next();
            let prf = feature.attribute("PARCELLE");
            if (prf !== null) {
                uniquePrfSet.add(prf);
            }
        }
        it.close()

        // Add the rest of the PRFs
        uniquePrfSet.forEach(prf => {
            prfListModel.append({ prf: prf });
        });
    }

    ListModel {
        id: varListModel
    }

    function resolveEssenceId(feature) {

        let id1 = feature.attribute("ESSENCE_ID")
        let id2 = feature.attribute("ESSENCE_SECONDAIRE_ID")

        if (id1 !== null && id1 !== undefined && String(id1).trim() !== "")
            return id1

        if (id2 !== null && id2 !== undefined && String(id2).trim() !== "")
            return id2

        return null
    }

    function getFormFactor(type) {

        const typeFF = {
            "Chênes": 0.8,
            "Hêtres": 0.8,
            "Douglas": 0.6,
            "Epicéas": 0.5,
            "Sapins": 0.5,
            "Feuillus": 0.8,
            "Résineux": 0.5
        }

        return typeFF[type] !== undefined ? typeFF[type] : 0.5
    }

    function getSurface(prfMode) {

        let param = qgisProject.mapLayersByName("Param")[0]
        if (!param)
            return null

        let expression = prfMode === "Toutes"
            ? "1=1"
            : `"PARCELLE" = '${prfMode}'`

        let it = LayerUtils.createFeatureIteratorFromExpression(param, expression)

        let surface = 0

        while (it.hasNext()) {
            let feature = it.next()
            let s = feature.attribute("SURFACE")
            if (s !== null && !isNaN(s))
                surface += Number(s)
        }

        it.close()
        return surface
    }

    function loadVarBy(mode) {

        let arbres = qgisProject.mapLayersByName("Arbres")[0]
        let essences = qgisProject.mapLayersByName("Essences")[0]
        let surfaceHa = getSurface(prfMode)

        if (!arbres || !essences)
            return

        varListModel.clear()

        let results = {}
        let expression = prfMode === "Toutes" ? "1=1" : `"PARCELLE" = '${prfMode}'`;
        let it = LayerUtils.createFeatureIteratorFromExpression(arbres, expression)

        // === SELECT MODE ===
        const modeFieldMap = {
            variation: "essence_variation",
            essence: "essence",
            type: "type"
        }

        while (it.hasNext()) {

            const feature = it.next()

            let id = resolveEssenceId(feature)
            if (!id)
                continue

            const essenceFeature = essences.getFeature(id)
            if (!essenceFeature)
                continue

            const essenceName = essenceFeature.attribute("essence_variation")

            // === SELECT MODE ===
            let key = "Toutes"
            if (modeFieldMap[mode]) {
                key = essenceFeature.attribute(modeFieldMap[mode]) || "Inconnu"
            }

            // === CALCULATE VOLUME ===
            const d = feature.attribute("DIAMETRE")
            const e = feature.attribute("EFFECTIF")
            const h = feature.attribute("HAUTEUR")
            const ff = getFormFactor(essenceFeature.attribute("type"))

            if (h == null || isNaN(h))
                continue

            const rayon = (d / 100) / 2
            const volume = ff * Math.PI * rayon * rayon * h * e
            const g = Math.PI * rayon * rayon * e 
            
            if (!results[key]) {
                results[key] = {
                    totalVolume: 0,
                    totalG: 0,
                    featureCount: 0
                }
            }

            results[key].totalVolume += volume
            results[key].totalG += g    
            results[key].featureCount++
        }

        it.close()

        for (let key in results) {

            let g = results[key]
            let vHa = surfaceHa > 0 ? g.totalVolume / surfaceHa : null
            let gHa = surfaceHa > 0 ? g.totalG / surfaceHa : null

            varListModel.append({
                essence: key,
                totalVolume: g.totalVolume < 10 ? g.totalVolume.toFixed(2) : g.totalVolume.toFixed(0),
                volumeUnitaire: (g.totalVolume / g.featureCount).toFixed(2),
                volumeHa: vHa !== null ? (vHa < 10 ? vHa.toFixed(2) : vHa.toFixed(0)) : "-",
                gha: gHa !== null ? (gHa < 10 ? gHa.toFixed(2) : gHa.toFixed(0)) : "-",
                effectif: g.featureCount.toFixed(0)
            })
        }
    }

}
