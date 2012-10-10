$.widget( "custom.catcomplete", $.ui.autocomplete, {
    _renderMenu: function( ul, items ) {
        var that = this,
            currentCategory = "";
        $.each( items, function( index, item ) {
            if ( item.category != currentCategory ) {
                ul.append( "<li class='ui-autocomplete-category'>" + item.category + "</li>" );
                currentCategory = item.category;
            }
            that._renderItemData( ul, item );
        });
    },
    _renderItem: function( ul, item ) {
        return $( "<li>" )
            .append( $( "<a>" ).text( item.visible_label) )
            .appendTo( ul );
    }
});
