$csharp = @"
using System;
using System.IO;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Collections.Generic;

public class SteerCatalogBuilder
{
    public class CatEntry
    {
        public string id { get; set; }
        public string name_ru { get; set; }
        public string file { get; set; }
        public string format { get; set; }
        public string url { get; set; }
        public string tag { get; set; }
        public string source { get; set; }
        public string source_name { get; set; }
        public bool default_on { get; set; }
        public string description_ru { get; set; }
    }

    public class DomEntry
    {
        public string id { get; set; }
        public string kind { get; set; }
        public string name_ru { get; set; }
        public string file { get; set; }
        public string format { get; set; }
        public string url { get; set; }
        public string tag { get; set; }
        public string source { get; set; }
        public string source_name { get; set; }
        public bool default_on { get; set; }
        public int count { get; set; }
        public List<string> same_as_ip { get; set; }
        public string description_ru { get; set; }
    }

    public static string CleanName(string rawTitle, string id)
    {
        if (string.IsNullOrWhiteSpace(rawTitle))
            return id;

        // Try extracting before " — " or " - "
        var m = Regex.Match(rawTitle, @"^(.*?)\s+[-—]\s+(.*)$");
        if (m.Success)
        {
            var shortName = m.Groups[1].Value.Trim();
            if (shortName.Length > 0 && shortName.Length < 40)
                return shortName;
        }

        return rawTitle;
    }

    public static void Build(string catalogPath, string outputPath, string repoOwner = "H1rolce")
    {
        var jsonBytes = File.ReadAllBytes(catalogPath);
        using var doc = JsonDocument.Parse(jsonBytes);
        var root = doc.RootElement;

        var categories = new List<CatEntry>();
        var domainLists = new List<DomEntry>();

        var prefix = "tachyon";
        var sourceRepo = "Dushnilin/tachyon-lists";
        var sourceTitle = "Tachyon Lists";
        var tag = "latest";

        if (root.TryGetProperty("lists", out var listsElem) && listsElem.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in listsElem.EnumerateArray())
            {
                var id = item.GetProperty("id").GetString();
                var title = item.TryGetProperty("title", out var tProp) ? tProp.GetString() : id;
                var desc = item.TryGetProperty("description", out var dProp) ? dProp.GetString() : "";

                int domCount = 0;
                int cidrCount = 0;

                if (item.TryGetProperty("counts", out var cElem))
                {
                    int d = cElem.TryGetProperty("domain", out var dp) ? dp.GetInt32() : 0;
                    int ds = cElem.TryGetProperty("domain_suffix", out var dsp) ? dsp.GetInt32() : 0;
                    int v4 = cElem.TryGetProperty("ipv4_cidr", out var v4p) ? v4p.GetInt32() : 0;
                    int v6 = cElem.TryGetProperty("ipv6_cidr", out var v6p) ? v6p.GetInt32() : 0;

                    domCount = d + ds;
                    cidrCount = v4 + v6;
                }

                bool hasDom = domCount > 0;
                bool hasCidr = cidrCount > 0;

                var cleanName = CleanName(title, id);
                var srsUrl = $"https://github.com/{sourceRepo}/releases/download/{tag}/{id}.srs";

                var catId = $"{prefix}:{id}";

                if (hasCidr)
                {
                    categories.Add(new CatEntry
                    {
                        id = catId,
                        name_ru = cleanName,
                        file = $"{prefix}/{id}.srs.lst",
                        format = "srs",
                        url = srsUrl,
                        tag = tag,
                        source = sourceRepo,
                        source_name = sourceTitle,
                        default_on = false,
                        description_ru = desc
                    });
                }

                if (hasDom)
                {
                    var domId = hasCidr ? $"svc_{prefix}_{id}" : catId;
                    var domEntry = new DomEntry
                    {
                        id = domId,
                        kind = "domains",
                        name_ru = cleanName,
                        file = $"{prefix}/domains/{id}.srs.lst",
                        format = "srs",
                        url = srsUrl,
                        tag = tag,
                        source = sourceRepo,
                        source_name = sourceTitle,
                        default_on = false,
                        count = domCount,
                        description_ru = desc
                    };

                    if (hasCidr)
                    {
                        domEntry.same_as_ip = new List<string> { catId };
                    }

                    domainLists.Add(domEntry);
                }
            }
        }

        var now = DateTime.UtcNow;
        var manifest = new Dictionary<string, object>
        {
            ["version"] = now.ToString("yyyy-MM-dd_HH-mm"),
            ["generated_at"] = now.ToString("yyyy-MM-ddTHH:mm:ssZ"),
            ["base_url"] = $"https://raw.githubusercontent.com/{repoOwner}/tachyon-lists/main/lists",
            ["categories"] = categories,
            ["domain_lists"] = domainLists
        };

        var options = new JsonSerializerOptions
        {
            WriteIndented = true,
            Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping,
            DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
        };

        var outputBytes = JsonSerializer.SerializeToUtf8Bytes(manifest, options);
        File.WriteAllBytes(outputPath, outputBytes);

        Console.WriteLine($"Generated {outputPath}:");
        Console.WriteLine($"  Categories (subnets): {categories.Count}");
        Console.WriteLine($"  Domain lists: {domainLists.Count}");
        Console.WriteLine($"  File size: {new FileInfo(outputPath).Length / 1024} KB");
    }
}
"@

Add-Type -TypeDefinition $csharp -Language CSharp
[SteerCatalogBuilder]::Build((Join-Path $PWD "catalog.json"), (Join-Path $PWD "lists.json"), "H1rolce")
