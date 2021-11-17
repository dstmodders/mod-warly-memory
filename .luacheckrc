exclude_files = {
    "scripts/devtools/sdk/",
    "workshop/",
}

std = {
    max_code_line_length = 100,
    max_comment_line_length = 150,
    max_line_length = 100,
    max_string_line_length = 100,

    -- std.read_globals should include only the "native" Lua-related stuff
    read_globals = {
        "arg",
        "assert",
        "Class",
        "debug",
        "env",
        "getmetatable",
        "ipairs",
        "json",
        "math",
        "next",
        "os",
        "pairs",
        "print",
        "rawset",
        "require",
        "string",
        "table",
        "tonumber",
        "tostring",
        "type",
        "unpack",
    },
}

files["modinfo.lua"] = {
    globals = {
        "all_clients_require_mod",
        "api_version",
        "author",
        "client_only_mod",
        "configuration_options",
        "description",
        "dont_starve_compatible",
        "dont_starve_compatible",
        "dst_compatible",
        "forumthread",
        "icon",
        "icon_atlas",
        "name",
        "reign_of_giants_compatible",
        "server_filter_tags",
        "shipwrecked_compatible",
        "version",
    },
}

files["modmain.lua"] = {
    globals = {
        "_G",
    },
    read_globals = {},
}

files["**/*.lua"] = {
    globals = {},
    read_globals = {},
}
