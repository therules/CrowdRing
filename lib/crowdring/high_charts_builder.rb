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
	        {title: {text: 'Total Calls'}, opposite: true, labels: {style: { color: 'green'}}}]
	      
	      f.options[:legend] = {enabled: true, verticalAlign: 'top'}

	      f.series(name: 'Total Calls', data: CampaignStats.calculate(campaign, :member_total), step: true, yAxis: 0, color: 'rgba(67, 142, 204, .5)')
	      colors = ['rgba(191, 59, 72, .5)', 'rgba(59, 59, 191, .5)', 'rgba(81, 191, 59, .5)']
	      campaign.voice_numbers.each_with_index do |num, i|
					f.series(name: "#{num.description}", data: CampaignStats.calculate(campaign, :member_total, num), step: true, yAxis: 0, color: colors[i % colors.count])
	      end
      end
		end
		module_function :basic_stats
	end
end