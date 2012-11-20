def make_story_channel(&block)
  story do |session|
    channel = session.opens_channel
    block.call(channel)
    channel.gets_close
    channel.sends_close
  end
end
