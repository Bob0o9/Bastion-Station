/// Sends information needed for uplinks
/datum/asset/json/uplink
	name = "uplink"
	early = TRUE

/datum/asset/json/uplink/generate()
	var/list/data = list()
	var/list/categories = list()
	var/list/items = list()
	for(var/datum/uplink_category/category as anything in subtypesof(/datum/uplink_category))
		categories += category
	sortTim(categories, GLOBAL_PROC_REF(cmp_uplink_category_desc))

	var/list/new_categories = list()
	for(var/datum/uplink_category/category as anything in categories)
		new_categories += initial(category.name)
	categories = new_categories

	for(var/datum/uplink_item/item_path as anything in subtypesof(/datum/uplink_item))
		var/datum/uplink_item/item = new item_path()
		var/atom/actual_item = item.item
		if(item.item) {
			items += list(list(
				"id" = item_path,
				"name" = item.name,
				"icon" = actual_item.icon,
				"icon_state" = actual_item.icon_state,
				"icon_id" = item.get_icon_id(),
				"cost" = item.cost,
				"desc" = item.desc,
				"category" = item.category ? initial(item.category.name) : null,
				"purchasable_from" = item.purchasable_from,
				"restricted" = item.restricted,
				"limited_stock" = item.limited_stock,
				"stock_key" = item.stock_key,
				"restricted_roles" = item.restricted_roles,
				"restricted_species" = item.restricted_species,
				"progression_minimum" = item.progression_minimum,
				"cost_override_string" = item.cost_override_string,
				"lock_other_purchases" = item.lock_other_purchases,
				"lock_secondary_objectives" = item.lock_secondary_objectives,
			))
		}
		SStraitor.uplink_items += item
		SStraitor.uplink_items_by_type[item_path] = item

	data["items"] = items
	data["categories"] = categories
	return data

/datum/asset/spritesheet_batched/uplink
	name = "uplink"

/datum/asset/spritesheet_batched/uplink/create_spritesheets()
	get_asset_datum(/datum/asset/json/uplink)
	var/list/seen = list()
	for(var/datum/uplink_item/item as anything in SStraitor.uplink_items)
		var/icon_id = item.get_icon_id()
		if(!icon_id || seen[icon_id])
			continue
		seen[icon_id] = TRUE
		var/datum/universal_icon/preview = get_display_icon_for(item.item)
		// Catalog slots share one atlas size, including previews of larger items.
		preview.scale(32, 32)
		insert_icon(icon_id, preview)
