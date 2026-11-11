' Works out a channel's broadcast the way spelunkr.tv does, so both show the same
' thing at the same moment: programs, up-next cards, bumper breaks and commercials.
' Break lengths depend on which bumper and commercial get picked, and each pick
' depends on earlier ones, so every cycle since the version's epoch is replayed.
'
' Roku Integers are 32-bit and overflow, so hashes are two 16-bit halves, and large
' times are Doubles. bcFloorDiv and bcToInteger avoid trusting Int() on large
' Doubles because the Roku docs define it on single-precision Float.

function spelunkrBroadcast(manifest as Object, platform as Dynamic, entry as Object, windowStartSec as Integer, windowEndSec as Integer) as Dynamic
    if type(platform) <> "roAssociativeArray" then return invalid
    ' Rules for any other engine version are unknown, so use the plain schedule.
    if not bcIsWhole(manifest.engine) then return invalid
    if manifest.engine <> 5 then return invalid
    channelBumps = bcBumpList(manifest.bumps)
    platformBumps = bcBumpList(platform.bumps)
    if channelBumps.all.Count() = 0 or platformBumps.all.Count() = 0 then return invalid
    items = manifest.items
    count = items.Count()
    if count = 0 then return invalid
    durations = []
    for each item in items
        durations.Push(Int(Val(spelunkrText(item.duration))))
    end for
    epochMs = entry.epochSec * 1000# + entry.epochMsRem
    windowEndMs = windowEndSec * 1000#
    state = {
        items: items, durations: durations, channelBumps: channelBumps, platformBumps: platformBumps,
        block: manifest.block, ads: invalid, plan: invalid, gapMs: 1200000#, channelId: entry.id,
        version: entry.version, deck: {order: [], cursor: 0, key: invalid, recent: [], rounds: 0},
        recent: [], fromMs: invalid, used: [], usedCount: 0, events: [], failed: false,
        windowStartMs: windowStartSec * 1000#, windowEndMs: windowEndMs, dayStart: 1#, dayEnd: 0#
    }
    ads = manifest.ads
    if type(ads) = "roAssociativeArray"
        if type(ads.slices) = "roArray"
            if ads.slices.Count() > 0
                state.ads = ads
                if bcIsWhole(ads.gapMs) then state.gapMs = ads.gapMs * 1#
            end if
        end if
    end if
    startIndex = entry.startIndex
    if startIndex < 0 or startIndex >= count then startIndex = 0
    cycleStart = epochMs
    cycle = 0
    while cycleStart < windowEndMs
        if cycle > 500 then return invalid
        cycleStart = bcRunCycle(state, cycle, startIndex, cycleStart)
        if state.failed then return invalid
        cycle = cycle + 1
    end while
    if state.events.Count() = 0 then return invalid
    return {id: entry.id, ok: true, events: state.events, endSec: state.events[state.events.Count() - 1].startSec + state.events[state.events.Count() - 1].duration}
end function

' Plays one cycle of the channel forward from its start and returns where it ended.
function bcRunCycle(s as Object, cycle as Integer, startIndex as Integer, startMs as Double) as Double
    first = 0
    if cycle = 0 then first = startIndex
    total = s.items.Count()
    lastIndex = total - 1
    seed = s.version.ToStr() + "." + cycle.ToStr()
    now = startMs
    sinceBlock = 0#
    sinceAd = 0#
    block = s.block
    hasBlock = type(block) = "roAssociativeArray"
    s.deck.rounds = 0
    pickedAds = []
    fromMs = s.fromMs
    if s.ads <> invalid then bcLoadUsed(s)
    for itemIndex = first to lastIndex
        item = s.items[itemIndex]
        itemMs = s.durations[itemIndex] * 1000#
        bcEmitVideo(s, item, itemIndex, now, itemMs)
        now = now + itemMs
        sinceBlock = sinceBlock + itemMs
        sinceAd = sinceAd + itemMs
        if now >= s.windowEndMs then return now
        nextCard = false
        if hasBlock and itemIndex < lastIndex
            if sinceBlock < block.lengthMs then nextCard = true
        end if
        if nextCard
            cardMs = bcCardLength(block, itemIndex, s.channelId, seed)
            bcEmitCard(s, now, cardMs, "Up Next", [{at: 0, text: "UP NEXT" + Chr(10) + spelunkrText(s.items[itemIndex + 1].title)}])
            now = now + cardMs
            sinceBlock = sinceBlock + cardMs
            sinceAd = sinceAd + cardMs
        else
            sinceBlock = 0#
            channelBump = bcDeckPick(s, s.channelBumps, s.channelId, seed, now)
            platformBump = bcBreakPick(s, s.platformBumps, "spelunkr", itemIndex, seed, now)
            if channelBump <> invalid and platformBump <> invalid
                following = s.items[0]
                if itemIndex < lastIndex then following = s.items[itemIndex + 1]
                adBreak = false
                if s.ads <> invalid and not bcIsTrue(item.offAir) and not bcIsTrue(following.offAir)
                    if sinceAd >= s.gapMs then adBreak = true
                end if
                if adBreak
                    since = now - sinceAd
                    if fromMs <> invalid then since = fromMs
                    if s.plan = invalid then s.plan = bcAdPlan(s)
                    sliceIndex = bcPickAd(s, bcYear(item.year), now, since)
                    if sliceIndex < 0
                        s.failed = true
                        return now
                    end if
                    fromMs = invalid
                    pickedAds.Push({slice: sliceIndex, atMs: now})
                    slice = s.ads.slices[sliceIndex]
                    openMs = 3500# + channelBump.ms + 2000#
                    closeMs = platformBump.ms + 2000#
                    bcEmitCard(s, now, openMs, "Station Break", bcSlides(channelBump, 3500))
                    now = now + openMs
                    sliceMs = slice.lengthMs * 1#
                    bcEmitAd(s, slice, now, sliceMs)
                    now = now + sliceMs
                    bcEmitCard(s, now, closeMs, "Station Break", bcSlides(platformBump, 0))
                    now = now + closeMs
                    sinceAd = closeMs
                    s.fromMs = now
                else
                    breakMs = 3500# + channelBump.ms + 2000# + 300# + platformBump.ms + 2000#
                    slides = bcSlides(channelBump, 3500)
                    slides.Append(bcSlides(platformBump, 3500 + bcToInteger(channelBump.ms) + 2300))
                    bcEmitCard(s, now, breakMs, "Station Break", slides)
                    now = now + breakMs
                    sinceAd = sinceAd + breakMs
                end if
            end if
        end if
    end for
    if s.ads <> invalid
        if pickedAds.Count() = 0
            if fromMs <> invalid then s.fromMs = fromMs else s.fromMs = startMs
        end if
        cutoff = now - 86400000#
        recent = []
        for each pick in s.recent
            if pick.atMs >= cutoff then recent.Push(pick)
        end for
        for each pick in pickedAds
            if pick.atMs >= cutoff then recent.Push(pick)
        end for
        s.recent = recent
    end if
    return now
end function

function bcCardLength(block as Object, itemIndex as Integer, channelId as String, seed as String) as Double
    stings = block.stings
    if type(stings) = "roArray"
        if stings.Count() > 0
            bcHash(channelId + "-card-" + itemIndex.ToStr() + "-" + seed)
            bcRngStart()
            bcRngNext()
            return stings[bcRngIndex(stings.Count())].lengthMs * 1#
        end if
    end if
    return block.cardMs * 1#
end function

' --- events ---------------------------------------------------------------------

sub bcEmitVideo(s as Object, item as Object, itemIndex as Integer, startMs as Double, lengthMs as Double)
    if startMs >= s.windowEndMs or startMs + lengthMs <= s.windowStartMs then return
    event = spelunkrItem(item, itemIndex)
    bcAddEvent(s, event, startMs, lengthMs)
end sub

sub bcEmitCard(s as Object, startMs as Double, lengthMs as Double, title as String, slides as Object)
    if startMs >= s.windowEndMs or startMs + lengthMs <= s.windowStartMs then return
    bcAddEvent(s, {kind: "card", index: -1, title: title, description: "", year: "", url: "", streamFormat: "mp4", inS: 0, slides: slides}, startMs, lengthMs)
end sub

sub bcEmitAd(s as Object, slice as Object, startMs as Double, lengthMs as Double)
    if startMs >= s.windowEndMs or startMs + lengthMs <= s.windowStartMs then return
    url = "https://archive.org/download/" + spelunkrText(slice.tape) + "/" + spelunkrPathEscape(spelunkrText(slice.file))
    fileStart = 0
    if slice.inMs <> invalid then fileStart = Int(slice.inMs / 1000)
    bcAddEvent(s, {kind: "ad", index: -1, title: "Commercial Break", description: "", year: spelunkrText(slice.year), url: url, streamFormat: "mp4", inS: fileStart, moov: spelunkrWhole(slice.moov)}, startMs, lengthMs)
end sub

sub bcAddEvent(s as Object, event as Object, startMs as Double, lengthMs as Double)
    startSec = bcSeconds(startMs)
    endSec = bcSeconds(startMs + lengthMs)
    if endSec <= startSec then return
    event.startSec = startSec
    event.duration = endSec - startSec
    s.events.Push(event)
end sub

function bcSlides(bump as Object, offsetMs as Integer) as Object
    slides = []
    at = offsetMs
    for each slide in bump.slides
        slides.Push({at: at, text: spelunkrText(slide.text)})
        at = at + bcSlideMs(spelunkrText(slide.text))
    end for
    return slides
end function

' --- bumpers --------------------------------------------------------------------

function bcBumpList(raw as Dynamic) as Object
    list = {all: [], live: [], yearRound: [], seasonal: [], memoStart: 1#, memoEnd: 0#, memoLive: [], memoKey: ""}
    if type(raw) <> "roArray" then return list
    for each bump in raw
        ms = 0
        slides = bump.slides
        if type(slides) <> "roArray" then slides = []
        for each slide in slides
            ms = ms + bcSlideMs(spelunkrText(slide.text))
        end for
        compact = {index: list.all.Count(), id: spelunkrText(bump.id), ms: ms * 1#, slides: slides, range: bump.date_range}
        list.all.Push(compact)
        isActive = true
        if bump.active <> invalid then isActive = bump.active <> false
        if isActive
            list.live.Push(compact)
            if type(compact.range) = "roArray" then list.seasonal.Push(compact) else list.yearRound.Push(compact)
        end if
    end for
    return list
end function

' How long a slide stays up. JavaScript counts an emoji as two characters.
function bcSlideMs(text as String) as Integer
    length = Len(text)
    for position = 1 to Len(text)
        if Asc(Mid(text, position, 1)) > 65535 then length = length + 1
    end for
    ms = 1500 + length * 55
    if ms < 2500 then ms = 2500
    return ms
end function

' Seasonal bumpers replace the year-round set while their dates are active. The
' answer only changes at midnight UTC, so it is kept for the rest of the day.
sub bcRefreshLive(s as Object, list as Object, atMs as Double)
    if atMs >= list.memoStart and atMs < list.memoEnd then return
    if not (atMs >= s.dayStart and atMs < s.dayEnd)
        day = bcFloorDiv(atMs, 86400000#)
        s.dayStart = day * 86400000#
        s.dayEnd = s.dayStart + 86400000#
        bcSetCalendarDay(s, day)
    end if
    list.memoStart = s.dayStart
    list.memoEnd = s.dayEnd
    key = ""
    anyActive = false
    for each bump in list.seasonal
        if bcInDateRange(s, bump.range)
            if anyActive then key = key + "|"
            key = key + bump.id
            anyActive = true
        end if
    end for
    list.memoKey = key
    if not anyActive
        list.memoLive = list.yearRound
        return
    end if
    live = []
    for each bump in list.live
        if type(bump.range) <> "roArray"
            live.Push(bump)
        else if bcInDateRange(s, bump.range)
            live.Push(bump)
        end if
    end for
    list.memoLive = live
end sub

' UTC calendar date from a count of days since 1970, by whole-number arithmetic.
sub bcSetCalendarDay(s as Object, day as Double)
    shifted = day + 719468
    era = bcFloorDiv(shifted, 146097#)
    dayOfEra = shifted - era * 146097
    yearOfEra = bcFloorDiv(dayOfEra - bcFloorDiv(dayOfEra, 1460#) + bcFloorDiv(dayOfEra, 36524#) - bcFloorDiv(dayOfEra, 146096#), 365#)
    dayOfYear = dayOfEra - (365 * yearOfEra + bcFloorDiv(yearOfEra, 4#) - bcFloorDiv(yearOfEra, 100#))
    shiftedMonth = bcFloorDiv(5 * dayOfYear + 2, 153#)
    s.dayNumber = bcToInteger(dayOfYear - bcFloorDiv(153 * shiftedMonth + 2, 5#) + 1)
    if shiftedMonth < 10 then s.dayMonth = bcToInteger(shiftedMonth + 3) else s.dayMonth = bcToInteger(shiftedMonth - 9)
    calendarYear = yearOfEra + era * 400
    if s.dayMonth <= 2 then calendarYear = calendarYear + 1
    s.dayText = bcToInteger(calendarYear).ToStr() + "-" + bcPad(s.dayMonth) + "-" + bcPad(s.dayNumber)
end sub

function bcInDateRange(s as Object, range as Object) as Boolean
    fromText = spelunkrText(range[0])
    toText = spelunkrText(range[1])
    if Mid(fromText, 5, 1) = "-" then return s.dayText >= fromText and s.dayText <= toText
    current = s.dayMonth * 100 + s.dayNumber
    firstDay = Int(Val(Left(fromText, 2))) * 100 + Int(Val(Mid(fromText, 4, 2)))
    lastDay = Int(Val(Left(toText, 2))) * 100 + Int(Val(Mid(toText, 4, 2)))
    if firstDay <= lastDay then return current >= firstDay and current <= lastDay
    return current >= firstDay or current <= lastDay
end function

function bcPad(value as Integer) as String
    if value < 10 then return "0" + value.ToStr()
    return value.ToStr()
end function

function bcBreakPick(s as Object, list as Object, label as String, breakIndex as Integer, seed as String, atMs as Double) as Dynamic
    if list.all.Count() = 0 then return invalid
    bcRefreshLive(s, list, atMs)
    live = list.memoLive
    if live.Count() = 0 then return invalid
    bcHash(label + "-break-" + breakIndex.ToStr() + "-" + seed)
    bcRngStart()
    bcRngNext()
    return live[bcRngIndex(live.Count())]
end function

' Channel bumpers are dealt like cards: shuffled, then used once each per round.
function bcDeckPick(s as Object, list as Object, label as String, seed as String, atMs as Double) as Dynamic
    if list.all.Count() = 0 then return invalid
    bcRefreshLive(s, list, atMs)
    live = list.memoLive
    if live.Count() = 0 then return invalid
    deck = s.deck
    rebuild = deck.key = invalid
    if not rebuild then rebuild = deck.key <> list.memoKey or deck.cursor >= deck.order.Count()
    if rebuild
        bcHash(label + "-deck-" + seed + "-" + deck.rounds.ToStr())
        deck.rounds = deck.rounds + 1
        deck.order = bcShuffle(live, deck.recent, list.all.Count())
        deck.cursor = 0
        deck.key = list.memoKey
    end if
    picked = deck.order[deck.cursor]
    deck.cursor = deck.cursor + 1
    deck.recent.Push(picked)
    if deck.recent.Count() > deck.order.Count() then deck.recent.Shift()
    return list.all[picked]
end function

' Expects the seed hash to be set. Shuffles, then moves anything used recently out
' of the early positions so a bumper does not repeat across a reshuffle.
function bcShuffle(live as Object, recent as Object, allCount as Integer) as Object
    bcRngStart()
    order = []
    for each bump in live
        order.Push(bump.index)
    end for
    size = order.Count()
    for position = size - 1 to 1 step -1
        bcRngNext()
        other = bcRngIndex(position + 1)
        held = order[position]
        order[position] = order[other]
        order[other] = held
    end for
    spacing = size >> 1
    limit = spacing
    if recent.Count() < limit then limit = recent.Count()
    if limit = 0 then return order
    rank = []
    for index = 0 to allCount - 1
        rank.Push(0)
    end for
    for back = limit to 1 step -1
        rank[recent[recent.Count() - back]] = spacing + 1 - back
    end for
    for back = 1 to limit
        bumpIndex = recent[recent.Count() - back]
        at = -1
        for index = 0 to size - 1
            if order[index] = bumpIndex
                at = index
                exit for
            end if
        end for
        if at >= 0 and at < rank[bumpIndex]
            choices = []
            for index = rank[bumpIndex] to size - 1
                if rank[order[index]] <= at then choices.Push(index)
            end for
            bcRngNext()
            target = choices[bcRngIndex(choices.Count())]
            held = order[at]
            order[at] = order[target]
            order[target] = held
        end if
    end for
    return order
end function

' --- commercials ----------------------------------------------------------------

sub bcLoadUsed(s as Object)
    size = s.ads.slices.Count()
    used = []
    for index = 0 to size - 1
        used.Push(false)
    end for
    usedCount = 0
    for each pick in s.recent
        if not used[pick.slice]
            used[pick.slice] = true
            usedCount = usedCount + 1
        end if
    end for
    s.used = used
    s.usedCount = usedCount
end sub

' Every commercial gets a fixed place on a wheel. Each break moves along the wheel
' with the clock and takes the next one fitting the show's era.
function bcAdPlan(s as Object) as Object
    slices = s.ads.slices
    size = slices.Count()
    ranked = bcRankSlices(slices)
    phases = []
    years = []
    totalMs = 0#
    for index = 0 to size - 1
        phases.Push(0)
        years.Push(bcYear(slices[index].year))
        totalMs = totalMs + slices[index].lengthMs
    end for
    for position = 0 to size - 1
        phases[ranked[position]] = bcToInteger(bcFloorDiv(position * 1000000#, size * 1#))
    end for
    plan = {phases: phases, ranked: ranked, years: years, tiersByYear: {}, tierCache: {}, decades: invalid, start: 0}
    if bcIsWhole(s.ads.decades)
        if s.ads.decades >= 1 then plan.decades = s.ads.decades
    end if
    start = s.ads.start
    useStart = false
    if bcIsWhole(start)
        if start >= 0 and start < 1000 then useStart = true
    end if
    if useStart
        plan.start = start * 1000
    else
        bcHash("ads-" + s.channelId)
        plan.start = (((m.hashHi mod 1000) * 536 + m.hashLo) mod 1000) * 1000
    end if
    bcAdRates(s, plan, totalMs / size)
    return plan
end function

sub bcAdRates(s as Object, plan as Object, sliceMs as Double)
    items = s.items
    size = items.Count()
    block = s.block
    hasBlock = type(block) = "roAssociativeArray"
    cycleMs = 0#
    sinceAd = 0#
    sinceBlock = 0#
    byYear = {}
    yearKeys = []
    for index = 0 to size - 1
        itemMs = s.durations[index] * 1000#
        cycleMs = cycleMs + itemMs
        sinceAd = sinceAd + itemMs
        sinceBlock = sinceBlock + itemMs
        card = false
        if hasBlock and index < size - 1
            if sinceBlock < block.lengthMs then card = true
        end if
        if card
            cycleMs = cycleMs + block.cardMs
            sinceAd = sinceAd + block.cardMs
            sinceBlock = sinceBlock + block.cardMs
        else
            sinceBlock = 0#
            following = items[(index + 1) mod size]
            if not bcIsTrue(items[index].offAir) and not bcIsTrue(following.offAir) and sinceAd >= s.gapMs
                year = bcYear(items[index].year)
                key = bcYearKey(year)
                if not byYear.DoesExist(key)
                    byYear[key] = 0
                    yearKeys.Push({key: key, year: year})
                end if
                byYear[key] = byYear[key] + 1
                cycleMs = cycleMs + 20000# + sliceMs
                sinceAd = 10000#
            else
                cycleMs = cycleMs + 20000#
                sinceAd = sinceAd + 20000#
            end if
        end if
    end for
    plan.cycleMs = cycleMs
    plan.byYear = byYear
    plan.yearKeys = yearKeys
end sub

function bcYearKey(year as Integer) as String
    return year.ToStr()
end function

' Slice order by a hash of each commercial's id, ties broken by id then position.
function bcRankSlices(slices as Object) as Object
    size = slices.Count()
    hashes = []
    ids = []
    order = []
    ' Most channels draw on the same commercials, so each is only hashed once.
    if m.adHashes = invalid
        m.adHashes = {}
        m.adHashes.SetModeCaseSensitive()
    end if
    for index = 0 to size - 1
        id = spelunkrText(slices[index].id)
        ids.Push(id)
        if not m.adHashes.DoesExist(id)
            bcHash("ad-" + id)
            bcRngStart()
            bcRngNext()
            m.adHashes[id] = ((m.rngHi * 15625) + ((m.rngLo * 15625) >> 16)) >> 10
        end if
        hashes.Push(m.adHashes[id])
        order.Push(index)
    end for
    width = 1
    while width < size
        merged = []
        start = 0
        while start < size
            middle = start + width
            if middle > size then middle = size
            finish = start + width * 2
            if finish > size then finish = size
            a = start
            b = middle
            while a < middle or b < finish
                takeLeft = b >= finish
                if not takeLeft and a < middle then takeLeft = bcSliceBefore(order[a], order[b], hashes, ids)
                if takeLeft
                    merged.Push(order[a])
                    a = a + 1
                else
                    merged.Push(order[b])
                    b = b + 1
                end if
            end while
            start = finish
        end while
        order = merged
        width = width * 2
    end while
    return order
end function

function bcSliceBefore(a as Integer, b as Integer, hashes as Object, ids as Object) as Boolean
    if hashes[a] <> hashes[b] then return hashes[a] < hashes[b]
    if ids[a] <> ids[b] then return ids[a] < ids[b]
    return a < b
end function

' A tier is the commercials close enough to a show's year. `kind` is 0 for all of
' them, 1 for within `tolerance` years, 2 for within `tolerance` decades.
function bcTier(s as Object, plan as Object, year as Integer, kind as Integer, tolerance as Integer) as Object
    key = year.ToStr() + "|" + kind.ToStr() + "|" + tolerance.ToStr()
    if plan.tierCache.DoesExist(key) then return plan.tierCache[key]
    list = []
    places = []
    for each index in plan.ranked
        include = false
        if bcIsTrue(s.ads.slices[index].anywhere)
            include = true
        else
            include = bcYearMatches(plan.years[index], year, kind, tolerance)
        end if
        if include
            list.Push(index)
            places.Push(plan.phases[index])
        end if
    end for
    breaks = 0
    for each entry in plan.yearKeys
        if bcYearMatches(entry.year, year, kind, tolerance) then breaks = breaks + plan.byYear[entry.key]
    end for
    needed = 0#
    if plan.cycleMs > 0 then needed = breaks * 1209600000# / plan.cycleMs
    healthy = list.Count() > 0 and list.Count() >= needed
    roundMs = 1209600000#
    if not healthy and list.Count() > 0
        roundMs = bcFloorDiv(list.Count() * plan.cycleMs, breaks * 1#)
        if roundMs < 3600000# then roundMs = 3600000#
    end if
    tier = {kind: kind, list: list, places: places, roundMs: roundMs, healthy: healthy}
    plan.tierCache[key] = tier
    return tier
end function

function bcYearMatches(candidate as Integer, year as Integer, kind as Integer, tolerance as Integer) as Boolean
    if kind = 0 then return true
    if candidate = -1 or year = -1 then return false
    if kind = 2
        difference = bcFloorYear(candidate) - bcFloorYear(year)
    else
        difference = candidate - year
    end if
    if difference < 0 then difference = -difference
    return difference <= tolerance
end function

function bcFloorYear(year as Integer) as Integer
    return Int(year / 10)
end function

function bcTiers(s as Object, plan as Object, year as Integer) as Object
    key = year.ToStr()
    if plan.tiersByYear.DoesExist(key) then return plan.tiersByYear[key]
    candidates = []
    if year = -1
        candidates.Push(bcTier(s, plan, -1, 0, 0))
    else
        candidates.Push(bcTier(s, plan, year, 1, 3))
        candidates.Push(bcTier(s, plan, year, 1, 6))
        if plan.decades <> invalid then candidates.Push(bcTier(s, plan, year, 2, plan.decades))
        candidates.Push(bcTier(s, plan, year, 0, 0))
    end if
    tiers = []
    keep = false
    for each tier in candidates
        if tier.healthy or tier.kind = 0 then keep = true
        if keep and tier.list.Count() > 0 then tiers.Push(tier)
    end for
    plan.tiersByYear[key] = tiers
    return tiers
end function

function bcPickAd(s as Object, year as Integer, atMs as Double, sinceMs as Double) as Integer
    plan = s.plan
    wheel = 1000000
    if s.usedCount >= plan.phases.Count()
        for index = 0 to s.used.Count() - 1
            s.used[index] = false
        end for
        s.usedCount = 0
    end if
    tiers = bcTiers(s, plan, year)
    anchors = []
    for each tier in tiers
        size = tier.list.Count()
        roundMs = tier.roundMs
        fromPlace = bcWheelPlace(sinceMs, roundMs, plan.start)
        toPlace = bcWheelPlace(atMs, roundMs, plan.start)
        reach = 0
        if atMs > sinceMs
            if atMs - sinceMs >= roundMs
                reach = wheel
            else
                reach = (toPlace - fromPlace + wheel) mod wheel
            end if
        end if
        cappedMs = 86400000#
        if roundMs < cappedMs then cappedMs = roundMs
        lookback = bcToInteger(bcFloorDiv(cappedMs * 1000000#, roundMs))
        anchor = bcLowerBound(tier.places, fromPlace + 1)
        anchors.Push(anchor)
        for step_ = 0 to size - 1
            at = (anchor + step_) mod size
            distance = (tier.places[at] - fromPlace + wheel) mod wheel
            if distance = 0 then distance = wheel
            if distance > reach then exit for
            if not s.used[tier.list[at]] then return bcTakeAd(s, tier.list[at])
        end for
        for step_ = 1 to size
            at = (anchor - step_ + size * 2) mod size
            if (fromPlace - tier.places[at] + wheel) mod wheel >= lookback then exit for
            if not s.used[tier.list[at]] then return bcTakeAd(s, tier.list[at])
        end for
    end for
    for tierIndex = 0 to tiers.Count() - 1
        tier = tiers[tierIndex]
        size = tier.list.Count()
        for step_ = 1 to size
            candidate = tier.list[(anchors[tierIndex] - step_ + size * 2) mod size]
            if not s.used[candidate] then return bcTakeAd(s, candidate)
        end for
    end for
    return -1
end function

function bcTakeAd(s as Object, index as Integer) as Integer
    if not s.used[index]
        s.used[index] = true
        s.usedCount = s.usedCount + 1
    end if
    return index
end function

function bcWheelPlace(atMs as Double, roundMs as Double, start as Integer) as Integer
    remainder = atMs - bcFloorDiv(atMs, roundMs) * roundMs
    if remainder < 0 then remainder = remainder + roundMs
    return (bcToInteger(bcFloorDiv(remainder * 1000000#, roundMs)) + start) mod 1000000
end function

function bcLowerBound(places as Object, target as Integer) as Integer
    low = 0
    high = places.Count()
    while low < high
        middle = (low + high) >> 1
        if places[middle] < target
            low = middle + 1
        else
            high = middle
        end if
    end while
    return low
end function

' --- values -----------------------------------------------------------------------

function bcIsTrue(value as Dynamic) as Boolean
    if value = invalid then return false
    if type(value) <> "Boolean" and type(value) <> "roBoolean" then return false
    return value
end function

function bcIsWhole(value as Dynamic) as Boolean
    if value = invalid then return false
    kind = type(value)
    return kind = "Integer" or kind = "roInt" or kind = "roInteger" or kind = "LongInteger" or kind = "roLongInteger"
end function

' A show's year as a number, or -1 when it has none. Reads leading digits as parseInt does.
function bcYear(value as Dynamic) as Integer
    text = spelunkrText(value).Trim()
    year = 0
    digits = 0
    for position = 1 to Len(text)
        code = Asc(Mid(text, position, 1))
        if code < 48 or code > 57 then exit for
        year = year * 10 + code - 48
        digits = digits + 1
        if digits = 9 then exit for
    end for
    if digits = 0 then return -1
    return year
end function

' Floors the Double quotient, as Math.floor(a / b) does on the site.
function bcFloorDiv(value as Double, divisor as Double) as Double
    quotient = value / divisor
    if quotient < 1000000000#
        whole = Int(quotient) * 1#
    else
        high = Int(quotient / 1000000#)
        whole = high * 1000000# + Int(quotient - high * 1000000#)
    end if
    while whole > quotient
        whole = whole - 1
    end while
    while whole + 1 <= quotient
        whole = whole + 1
    end while
    return whole
end function

function bcToInteger(value as Double) as Integer
    high = Int(value / 65536#)
    rest = value - high * 65536#
    while rest < 0
        high = high - 1
        rest = rest + 65536
    end while
    while rest >= 65536
        high = high + 1
        rest = rest - 65536
    end while
    return high * 65536 + Int(rest)
end function

function bcSeconds(ms as Double) as Integer
    return bcToInteger(bcFloorDiv(ms, 1000#))
end function

' --- 32-bit hash and generator, matching the site's -----------------------------

sub bcHash(text as String)
    high = 0
    low = 0
    for position = 1 to Len(text)
        code = Asc(Mid(text, position, 1))
        if code > 65535
            code = code - 65536
            lead = 55296 + (code >> 10)
            low = low * 31 + lead
            high = (high * 31 + (low >> 16)) and 65535
            low = low and 65535
            code = 56320 + (code and 1023)
        end if
        low = low * 31 + code
        high = (high * 31 + (low >> 16)) and 65535
        low = low and 65535
    end for
    m.hashHi = high
    m.hashLo = low
end sub

sub bcRngStart()
    m.rngStateHi = m.hashHi
    m.rngStateLo = m.hashLo
end sub

' One draw; the result's two halves are left in m.rngHi and m.rngLo.
sub bcRngNext()
    low = m.rngStateLo + 31221
    high = (m.rngStateHi + 27947 + (low >> 16)) and 65535
    low = low and 65535
    m.rngStateHi = high
    m.rngStateLo = low
    shiftedLow = ((high and 32767) << 1) or (low >> 15)
    shiftedHigh = high >> 15
    bcMultiply(bcXor(high, shiftedHigh), bcXor(low, shiftedLow), high, low or 1)
    nHigh = m.mulHi
    nLow = m.mulLo
    shiftedLow = ((nHigh and 127) << 9) or (nLow >> 7)
    shiftedHigh = nHigh >> 7
    bcMultiply(bcXor(nHigh, shiftedHigh), bcXor(nLow, shiftedLow), nHigh, nLow or 61)
    sumLow = nLow + m.mulLo
    sumHigh = (nHigh + m.mulHi + (sumLow >> 16)) and 65535
    sumLow = sumLow and 65535
    nHigh = bcXor(nHigh, sumHigh)
    nLow = bcXor(nLow, sumLow)
    m.rngLo = bcXor(nLow, ((nHigh and 16383) << 2) or (nLow >> 14))
    m.rngHi = bcXor(nHigh, nHigh >> 14)
end sub

' floor(draw * size), without going through a rounded fraction.
function bcRngIndex(size as Integer) as Integer
    return ((m.rngHi * size) + ((m.rngLo * size) >> 16)) >> 16
end function

function bcXor(a as Integer, b as Integer) as Integer
    return (a or b) - (a and b)
end function

' Low 32 bits of a product, left in m.mulHi and m.mulLo. Bytes keep every
' intermediate value well under the 32-bit Integer limit.
sub bcMultiply(aHigh as Integer, aLow as Integer, bHigh as Integer, bLow as Integer)
    partOne = aLow * (bLow and 255)
    partTwo = aLow * (bLow >> 8)
    lowSum = partOne + ((partTwo and 255) << 8)
    carry = (lowSum >> 16) + (partTwo >> 8)
    m.mulLo = lowSum and 65535
    m.mulHi = (carry + bcLow16Product(aHigh, bLow) + bcLow16Product(aLow, bHigh)) and 65535
end sub

function bcLow16Product(a as Integer, b as Integer) as Integer
    return (a * (b and 255) + ((a * (b >> 8)) and 255) * 256) and 65535
end function
