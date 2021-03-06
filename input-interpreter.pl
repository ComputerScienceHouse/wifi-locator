#!/usr/bin/perl

use XML::Simple;
use Data::Dumper;
use strict;
use warnings;
use profiles;

#Could take a while.
print "Starting profile import...\n";
my @profiles = @{import_profile_data("rt2860")};
print "Done with profile import.\n";
my $xml = new XML::Simple;

open(my $XML_INPUT, "./iwlist ra0 scan |");

my $data = $xml->parse_fh($XML_INPUT);

my @cells;

#Populate array of cells
foreach my $cell (@{$data->{cell}}){
	my %current_cell = xml_cell_to_hash_cell($cell);
	push(@cells,\%current_cell);
}

@deltas = sum_delta_weight(\@profiles , \@cells);
print get_midpoint(@deltas);

#print "Best delta value: $best_delta\nClosest x: $best_x\nClosest y: $best_y\n";

sub get_midpoint
{
	my @deltas = @_;

	my ($x_sum, $y_sum, $weight_sum) = (0,0,0);
	foreach my $entry (@deltas){
		
		$x_sum += $entry{'x'} * $entry{'weight'};
		$y_sum += $entry{'y'} * $entry{'weight'};
		$weight_sum += $entry{'weight'};
	}
	
	my @x_y;

	push(@x_y , $x_sum / $weight_sum);
	push(@x_y , $y_sum / $weight_sum);
	
	return @x_y;
}

#Defines the weigts as the sum of the delta's
#between the current posistions signal and noise
#and the cells signal and noise
sub sum_delta_weight
{
	my @profiles = @{$_[0]};
	my @cells = @{$_[1]};

	#print @profiles;
	#print @cells;

	#Since a lower delta is better, we have to subtract from max_weight
	#to get a correctly weighted set
	my $max_delta_sum = 0;

	my @deltas;
	
	#Generate change value.
	#Somewhat verbose in order to prevent the array of pointers to hashes with pointers 
	#to arrays of pointers to hashes from being a total goat screw.
	foreach my $profile_ptr (@profiles){
		my %profile = %{$profile_ptr};
		my @profile_cells = @{$profile{'cells'}};
		my $delta_sum=0;
		foreach my $profile_cell (@profile_cells){
			foreach my $cell_ptr (@cells){
				my %cell = %{$cell_ptr};
				
				my $num_elements = 0;
				
				if(${$profile_cell}{'address'} eq $cell{'address'}){
										
					${$profile_cell}{'delta'} = abs($cell{'signal'} - ${$profile_cell}{'signal'}) + 
												abs($cell{'noise'} - ${$profile_cell}{'noise'});

					$delta_sum += ${$profile_cell}{'delta'};
				}
			}
		}
		
		print $delta_sum;
		#$profile{'weight'} = $delta_sum;

		my $entry = ();

		$entry{'x'} = $profiles{'x'};
		$entry{'y'} = $profiles{'y'};
		$entry{'weight'} = $delta_sum;

		push(@deltas , $entry);

		if($delta_sum > $max_delta_sum)
		{
			$max_delta_sum = $delta_sum;
		}
	}

	#Now we adjust the delta's based off the max_delta_sum 
	foreach my $entry (@deltas){
		#Add one so that the max_delta_sum profile is not excluded from the 
		#midpoint calculation
		$entry{'weight'} = $max_delta_sum - $entry{'weight'} + 1;
	}

	return @deltas;
}

#Defines the weights as the sum of the times the
#current posistions delta with the cell is minimal
#sub sum_min_delta_weight(@profiles, @cells)
#{

#}

#Still need to figure out how to implement this
#sub trim_outliers(@profiles)
#{
	#foreach my $profile_ptr 
#}
