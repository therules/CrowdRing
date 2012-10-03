module Crowdring
	module HighChartsBuilder
		def basic_stats(campaign)
			LazyHighCharts::HighChart.new('graph') do |f|
	      f.options[:chart][:zoomType] = 'x'
	      f.options[:title] = {text: ''}
	      f.options[:plotOptions][:area] = {marker: {enabled: false}}
	      f.options[:plotOptions][:line] = {marker: {enabled: false}}
	      f.options[:xAxis] = {ordinal: false, type: 'datetime'}
	      f.options[:tooltip] = {yDecimals: 0}
        f.options[:yAxis] = [
	        {title: {text: 'New Calls/Day'}, labels: {style: { color: 'rgba(67, 142, 204, 1)'}}}, 
	        {title: {text: 'Total Calls'}, opposite: true, labels: {style: { color: 'green'}}}]
	      
	      f.options[:legend] = {enabled: true, verticalAlign: 'top'}
	      
	      f.series(name: 'Total Calls', data: CampaignStats.calculate(campaign, :member_total), step: true, yAxis: 0, color: 'rgba(67, 142, 204, .5)', type: 'area')
	      f.series(name: 'New Calls/Day', data: CampaignStats.calculate(campaign, :new_members_per_day), yAxis: 1, color: 'green', type: 'line')
      end
		end
		module_function :basic_stats
	end
end