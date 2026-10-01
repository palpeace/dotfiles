-- Markdown を書くときの補助と、Claude Code に合わせた行の編集のキー。
-- キーは bindings.json で割り当てる。Markdown の補助は Markdown のバッファでだけ動く。
local micro = import("micro")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local util = import("micro/util")

local function isMarkdown(bp)
    return bp.Buf:FileType() == "markdown"
end

-- 行頭のリスト記号を、字下げ・記号・本文に分ける。リストでなければ nil
local function splitListItem(line)
    for _, pattern in ipairs({
        "^(%s*)([-*+] %[[ xX]%] )(.*)$",
        "^(%s*)(%d+[.)] %[[ xX]%] )(.*)$",
        "^(%s*)([-*+] )(.*)$",
        "^(%s*)(%d+[.)] )(.*)$",
    }) do
        local indent, mark, rest = line:match(pattern)
        if mark then
            return indent, mark, rest
        end
    end
end

-- 次の項目の記号。番号は1つ進め、チェックは外す
local function nextMark(mark)
    local n, rest = mark:match("^(%d+)(.*)$")
    if n then
        mark = (tonumber(n) + 1) .. rest
    end
    return (mark:gsub("%[[xX]%]", "[ ]"))
end

-- リストの項目で Enter を押したら、次の行に同じ記号を入れる。
-- 中身の無い項目で押したら、記号を消してリストを抜ける。
function preInsertNewline(bp)
    if not isMarkdown(bp) then
        return true
    end
    local c = bp.Cursor
    if c:HasSelection() or bp.Buf:NumCursors() > 1 then
        return true
    end
    local line = bp.Buf:Line(c.Y)
    local indent, mark, rest = splitListItem(line)
    if not mark or c.X < #indent + #mark then
        return true
    end
    if rest:match("^%s*$") then
        bp.Buf:Remove(buffer.Loc(0, c.Y), buffer.Loc(util.CharacterCountInString(line), c.Y))
        return false
    end
    bp.Buf:Insert(buffer.Loc(c.X, c.Y), "\n" .. indent .. nextMark(mark))
    return false
end

-- 今の行のチェックを入れ外しする。チェックの無い項目には [ ] を付ける
function toggleCheckbox(bp)
    if not isMarkdown(bp) then
        return false
    end
    local y = bp.Cursor.Y
    local line = bp.Buf:Line(y)
    local head = line:match("^(%s*[-*+] )") or line:match("^(%s*%d+[.)] )")
    if not head then
        return false
    end
    local box = line:sub(#head + 1, #head + 3)
    local from, to = buffer.Loc(#head, y), buffer.Loc(#head + 3, y)
    if box == "[ ]" then
        bp.Buf:Replace(from, to, "[x]")
    elseif box == "[x]" or box == "[X]" then
        bp.Buf:Replace(from, to, "[ ]")
    else
        bp.Buf:Insert(from, "[ ] ")
    end
    return true
end

-- 見出しの行番号（0 始まり）。コードブロックの中の # は数えない
local function headingLines(buf)
    local lines, inFence = {}, false
    for y = 0, buf:LinesNum() - 1 do
        local line = buf:Line(y)
        if line:match("^%s*```") or line:match("^%s*~~~") then
            inFence = not inFence
        elseif not inFence and line:match("^#+%s") then
            table.insert(lines, y)
        end
    end
    return lines
end

local function gotoLine(bp, y)
    bp.Cursor:ResetSelection()
    bp.Cursor:GotoLoc(buffer.Loc(0, y))
    bp:Relocate()
end

function nextHeading(bp)
    if not isMarkdown(bp) then
        return false
    end
    for _, y in ipairs(headingLines(bp.Buf)) do
        if y > bp.Cursor.Y then
            gotoLine(bp, y)
            return true
        end
    end
    return false
end

function prevHeading(bp)
    if not isMarkdown(bp) then
        return false
    end
    local lines = headingLines(bp.Buf)
    for i = #lines, 1, -1 do
        if lines[i] < bp.Cursor.Y then
            gotoLine(bp, lines[i])
            return true
        end
    end
    return false
end

-- 保存してから glow で整形して読む。glow を閉じると micro に戻る
function preview(bp)
    if not isMarkdown(bp) then
        return false
    end
    bp:Save()
    local path = "'" .. bp.Buf.AbsPath:gsub("'", "'\\''") .. "'"
    local _, err = shell.RunInteractiveShell("glow -t " .. path, false, false)
    if err ~= nil then
        micro.InfoBar():Error("glow: " .. tostring(err))
        return false
    end
    return true
end

-- Claude Code の入力欄と同じ、行の編集のキー（readline 式）。
-- 消した文字は OS のクリップボードに入れず、ここに持って Ctrl-Y で貼る
-- （clipboard が terminal だと、micro は端末のクリップボードを読み戻せないため）。
-- こちらはファイルの種類を問わずに動く。
local killed = ""

local function kill(bp, selectAction)
    bp.Cursor:ResetSelection()
    selectAction(bp)
    if not bp.Cursor:HasSelection() then
        return false
    end
    killed = util.String(bp.Cursor:GetSelection())
    bp:Delete()
    return true
end

function killToEnd(bp)
    return kill(bp, function(b) b:SelectToEndOfLine() end)
end

function killToStart(bp)
    return kill(bp, function(b) b:SelectToStartOfLine() end)
end

function killWordLeft(bp)
    return kill(bp, function(b) b:SelectWordLeft() end)
end

function killWordRight(bp)
    return kill(bp, function(b) b:SelectWordRight() end)
end

function yank(bp)
    if killed == "" then
        return false
    end
    bp.Buf:Insert(buffer.Loc(bp.Cursor.X, bp.Cursor.Y), killed)
    return true
end
