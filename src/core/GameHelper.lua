
GameHelper = {}
GameHelper.UnitModelPathGetter = {
    _helperItem = nil,
    Init = function(self)
        self._helperItem = CreateItem(FourCC('ratf'), 0, 0)
        SetItemVisible(self._helperItem, false)
    end,
    Get = function(self, unit)
        BlzSetItemSkin(self._helperItem, GetUnitTypeId(unit))
        return BlzGetItemStringField(self._helperItem, ITEM_SF_MODEL_USED)
    end
}

GameHelper.UnitModelPathGetter:Init()