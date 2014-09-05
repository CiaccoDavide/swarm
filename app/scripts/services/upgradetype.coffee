'use strict'

angular.module('swarmApp').factory 'UpgradeType', -> class UpgradeType
  constructor: (data) ->
    _.extend this, data

angular.module('swarmApp').factory 'UpgradeTypes', (spreadsheetUtil, UpgradeType, util) -> class UpgradeTypes
  constructor: (@unittypes, upgrades=[]) ->
    @list = []
    @byName = {}
    for upgrade in upgrades
      @register upgrade

  register: (upgrade) ->
    util.assert upgrade.name, 'upgrade without a name', upgrade
    @list.push upgrade
    @byName[upgrade.name] = upgrade

  @parseSpreadsheet: (unittypes, effecttypes, data) ->
    rows = spreadsheetUtil.parseRows {name:['requires','cost','effect']}, data.data.upgrades.elements
    ret = new UpgradeTypes unittypes, (new UpgradeType(row) for row in rows when row.name)
    for upgrade in ret.list
      spreadsheetUtil.resolveList [upgrade], 'unittype', unittypes.byName
      spreadsheetUtil.resolveList upgrade.cost, 'unittype', unittypes.byName
      spreadsheetUtil.resolveList upgrade.requires, 'unittype', unittypes.byName
      spreadsheetUtil.resolveList upgrade.effect, 'unittype', unittypes.byName
      spreadsheetUtil.resolveList upgrade.effect, 'type', effecttypes.byName
      for cost in upgrade.cost
        util.assert cost.val > 0, "upgradetype cost.val must be positive", cost
        if upgrade.maxlevel == 1
          cost.factor = 1
        util.assert cost.factor > 0, "upgradetype cost.factor must be positive", cost
    # resolve unittype.require.upgradetype, since upgrades weren't available when it was parsed. kinda hacky.
    for unittype in unittypes.list
      spreadsheetUtil.resolveList unittype.requires, 'upgradetype', ret.byName, {required:false}
    return ret

###*
 # @ngdoc service
 # @name swarmApp.upgrade
 # @description
 # # upgrade
 # Factory in the swarmApp.
###
angular.module('swarmApp').factory 'upgradetypes', (UpgradeTypes, unittypes, effecttypes, spreadsheet) ->
  return UpgradeTypes.parseSpreadsheet unittypes, effecttypes, spreadsheet
