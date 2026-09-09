local DataTypeLoader = {}

local DataTypes = {}

function DataTypeLoader:LoadDataTypes()
    local dataTypesFolder = script.Parent:WaitForChild("DataTypes")
    for _, dataType in ipairs(dataTypesFolder:GetChildren()) do
        DataTypes[dataType.Name] = require(dataType :: any) :: any
    end
end

function DataTypeLoader:CallDataType(dataType: string, ...)
    local dataTypeFunc = DataTypes[dataType]
    if dataTypeFunc then
        return dataTypeFunc(...)
    end
    return nil
end

return DataTypeLoader
