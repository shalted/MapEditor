using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using UnityEngine;

public class ExcelRow
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Type { get; set; }
    public string Model { get; set; }
    public string Position { get; set; }
    public string IsLogic { get; set; }
}

namespace Script
{
    public static class DataSlgElem
    {
        public static void ReadExcelXml(string filePath, ref Dictionary<int, ExcelRow> slgElemData)
        {
            XNamespace ss = "urn:schemas-microsoft-com:office:spreadsheet";
            var xDoc = XDocument.Load(filePath);

            if (xDoc.Root == null) return;
            var firstWorksheet = xDoc.Root.Elements(ss + "Worksheet").FirstOrDefault();

            if (firstWorksheet == null)
            {
                Console.WriteLine("未找到任何工作表！");
                return;
            }

            var rows = firstWorksheet.Descendants(ss + "Row").Skip(1)
                .Select(row => new ExcelRow
                {
                    Id = GetCellValue<int>(row, ss, 0),      // 第1个 Cell
                    Name = GetCellValue<string>(row, ss, 1), // 第2个 Cell
                    Type = GetCellValue<string>(row, ss, 2),
                    Model = GetCellValue<string>(row, ss, 3),
                    Position = GetCellValue<string>(row, ss, 4),
                    IsLogic = GetCellValue<string>(row, ss, 5)
                });
            slgElemData = rows.ToDictionary(row => row.Id);
        }

// 通用方法：根据索引获取 Cell 值，并转换类型
        private static T GetCellValue<T>(XElement row, XNamespace ns, int cellIndex)
        {
            var cell = row.Elements(ns + "Cell").ElementAt(cellIndex);
            var data = cell.Element(ns + "Data");
            var value = data?.Value ?? string.Empty;
            // 根据 ss:Type 转换数据类型
            var type = data?.Attribute(ns + "Type")?.Value;
            return type switch
            {
                "Number" => (T)Convert.ChangeType(value, typeof(T)),
                "String" => (T)(object)value,
                _ => default(T)
            };
        }
    }
}


