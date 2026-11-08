$csharpSource = @"
using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Text.Json;

public class TachyonBuilder
{
    public class RuleContainer
    {
        public HashSet<string> Domains = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        public HashSet<string> Suffixes = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        public HashSet<string> Keywords = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        public HashSet<string> Regexes = new HashSet<string>(StringComparer.Ordinal);
        public HashSet<string> IpCidrs = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        public void Absorb(JsonElement root)
        {
            if (root.TryGetProperty("rules", out var rulesElem) && rulesElem.ValueKind == JsonValueKind.Array)
            {
                foreach (var rule in rulesElem.EnumerateArray())
                {
                    if (rule.TryGetProperty("domain", out var dElem) && dElem.ValueKind == JsonValueKind.Array)
                        foreach (var item in dElem.EnumerateArray())
                            if (item.ValueKind == JsonValueKind.String)
                                Domains.Add(item.GetString());

                    if (rule.TryGetProperty("domain_suffix", out var sElem) && sElem.ValueKind == JsonValueKind.Array)
                        foreach (var item in sElem.EnumerateArray())
                            if (item.ValueKind == JsonValueKind.String)
                                Suffixes.Add(item.GetString());

                    if (rule.TryGetProperty("domain_keyword", out var kElem) && kElem.ValueKind == JsonValueKind.Array)
                        foreach (var item in kElem.EnumerateArray())
                            if (item.ValueKind == JsonValueKind.String)
                                Keywords.Add(item.GetString());

                    if (rule.TryGetProperty("domain_regex", out var rElem) && rElem.ValueKind == JsonValueKind.Array)
                        foreach (var item in rElem.EnumerateArray())
                            if (item.ValueKind == JsonValueKind.String)
                                Regexes.Add(item.GetString());

                    if (rule.TryGetProperty("ip_cidr", out var ipElem) && ipElem.ValueKind == JsonValueKind.Array)
                        foreach (var item in ipElem.EnumerateArray())
                            if (item.ValueKind == JsonValueKind.String)
                                IpCidrs.Add(item.GetString());
                }
            }
        }

        public void WriteRuleSet(Utf8JsonWriter writer)
        {
            writer.WriteStartObject();
            writer.WriteNumber("version", 3);
            writer.WriteStartArray("rules");
            writer.WriteStartObject();

            if (Domains.Count > 0)
            {
                writer.WriteStartArray("domain");
                foreach (var d in Domains.OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
                    writer.WriteStringValue(d);
                writer.WriteEndArray();
            }

            if (Suffixes.Count > 0)
            {
                writer.WriteStartArray("domain_suffix");
                foreach (var s in Suffixes.OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
                    writer.WriteStringValue(s);
                writer.WriteEndArray();
            }

            if (Keywords.Count > 0)
            {
                writer.WriteStartArray("domain_keyword");
                foreach (var k in Keywords.OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
                    writer.WriteStringValue(k);
                writer.WriteEndArray();
            }

            if (Regexes.Count > 0)
            {
                writer.WriteStartArray("domain_regex");
                foreach (var r in Regexes.OrderBy(x => x, StringComparer.Ordinal))
                    writer.WriteStringValue(r);
                writer.WriteEndArray();
            }

            if (IpCidrs.Count > 0)
            {
                writer.WriteStartArray("ip_cidr");
                foreach (var ip in IpCidrs.OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
                    writer.WriteStringValue(ip);
                writer.WriteEndArray();
            }

            writer.WriteEndObject();
            writer.WriteEndArray();
            writer.WriteEndObject();
        }
    }

    public static void Run(string jsonDir, string catalogPath, string outDir)
    {
        var files = Directory.GetFiles(jsonDir, "*.json");
        Console.WriteLine($"[1/5] Reading catalog and {files.Length} source JSON files...");

        // Load catalog actions: listId -> recommended_action
        var actionMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        if (File.Exists(catalogPath))
        {
            using (var catDoc = JsonDocument.Parse(File.ReadAllBytes(catalogPath)))
            {
                if (catDoc.RootElement.TryGetProperty("lists", out var listsElem))
                {
                    foreach (var item in listsElem.EnumerateArray())
                    {
                        var id = item.GetProperty("id").GetString();
                        var act = item.GetProperty("recommended_action").GetString();
                        actionMap[id] = act;
                    }
                }
            }
        }

        var allRules = new RuleContainer();
        var proxyRules = new RuleContainer();
        var directRules = new RuleContainer();
        var blockRules = new RuleContainer();

        // 1. tachyon_all_bundle.json: { id: { version: 3, rules: [...] } }
        Console.WriteLine("[2/5] Creating tachyon_all_bundle.json...");
        var bundlePath = Path.Combine(outDir, "tachyon_all_bundle.json");
        using (var fs = File.Create(bundlePath))
        using (var writer = new Utf8JsonWriter(fs, new JsonWriterOptions { Indented = false }))
        {
            writer.WriteStartObject();
            foreach (var f in files.OrderBy(x => Path.GetFileName(x), StringComparer.OrdinalIgnoreCase))
            {
                var id = Path.GetFileNameWithoutExtension(f);
                writer.WritePropertyName(id);

                using (var doc = JsonDocument.Parse(File.ReadAllBytes(f)))
                {
                    doc.RootElement.WriteTo(writer);

                    allRules.Absorb(doc.RootElement);

                    actionMap.TryGetValue(id, out var act);
                    if (string.Equals(act, "direct", StringComparison.OrdinalIgnoreCase))
                        directRules.Absorb(doc.RootElement);
                    else if (string.Equals(act, "block", StringComparison.OrdinalIgnoreCase))
                        blockRules.Absorb(doc.RootElement);
                    else
                        proxyRules.Absorb(doc.RootElement); // default to proxy
                }
            }
            writer.WriteEndObject();
        }

        // 2. tachyon_unified_ruleset.json
        Console.WriteLine("[3/5] Creating tachyon_unified_ruleset.json...");
        var unifiedPath = Path.Combine(outDir, "tachyon_unified_ruleset.json");
        using (var fs = File.Create(unifiedPath))
        using (var writer = new Utf8JsonWriter(fs, new JsonWriterOptions { Indented = false }))
        {
            allRules.WriteRuleSet(writer);
        }

        // 3. tachyon_by_action.json: { proxy: ruleSet, direct: ruleSet, block: ruleSet }
        Console.WriteLine("[4/5] Creating tachyon_by_action.json...");
        var byActionPath = Path.Combine(outDir, "tachyon_by_action.json");
        using (var fs = File.Create(byActionPath))
        using (var writer = new Utf8JsonWriter(fs, new JsonWriterOptions { Indented = false }))
        {
            writer.WriteStartObject();

            writer.WritePropertyName("proxy");
            proxyRules.WriteRuleSet(writer);

            writer.WritePropertyName("direct");
            directRules.WriteRuleSet(writer);

            writer.WritePropertyName("block");
            blockRules.WriteRuleSet(writer);

            writer.WriteEndObject();
        }

        // 4. Also standalone rule-sets for proxy, direct, block
        Console.WriteLine("[5/5] Creating separate action rule-sets (proxy/direct/block)...");
        void WriteSeparate(string fileName, RuleContainer container)
        {
            var p = Path.Combine(outDir, fileName);
            using (var fs = File.Create(p))
            using (var writer = new Utf8JsonWriter(fs, new JsonWriterOptions { Indented = false }))
            {
                container.WriteRuleSet(writer);
            }
        }

        WriteSeparate("tachyon_proxy_ruleset.json", proxyRules);
        WriteSeparate("tachyon_direct_ruleset.json", directRules);
        WriteSeparate("tachyon_block_ruleset.json", blockRules);

        Console.WriteLine("Done! All JSON files built successfully.");
    }
}
"@

Add-Type -TypeDefinition $csharpSource -Language CSharp
[TachyonBuilder]::Run((Join-Path $PWD "json_lists"), (Join-Path $PWD "catalog.json"), $PWD)
