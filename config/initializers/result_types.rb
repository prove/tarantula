require "#{Rails.root}/lib/result_type"

Passed =  ResultType.new(:db => 'PASSED',  
                         :ui => 'PASSED',
                         :rank => 5,
                         :color => '#00AA00')

Failed =  ResultType.new(:db => 'FAILED',  
                         :ui => 'FAILED', 
                         :rank => 1,
                         :color => '#AA0000')

Skipped = ResultType.new(:db => 'SKIPPED', 
                         :ui => 'SKIPPED', 
                         :rank => 2,
                         :color => '#BBCC00')

NotImplemented = ResultType.new(:db => 'NOT_IMPL', 
                                :ui => 'NOT_IMPLEMENTED',
                                :rank => 3,
                                :color => '#0000AA')
                            
NotRun =  ResultType.new(:db => 'NOT_RUN', 
                         :ui => 'NOT_RUN', 
                         :rank => 4,
                         :color => '#888888')
